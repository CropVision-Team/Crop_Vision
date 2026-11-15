import os
import random
import torch
import torch.nn.functional as F
from torchvision import datasets, transforms
from torch.utils.data import DataLoader, Subset
import timm

IMG_SIZE = 256
MEAN = [0.485, 0.456, 0.406]
STD  = [0.229, 0.224, 0.225]

def split_indices(n, val_frac=0.15, test_frac=0.15, seed=42):
    idx = list(range(n))
    random.Random(seed).shuffle(idx)
    v = int(n * val_frac)
    t = int(n * test_frac)
    return idx[v + t:], idx[:v], idx[v:v + t]

def main():
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Device: {device}")

    eval_transform = transforms.Compose([
        transforms.Resize((IMG_SIZE, IMG_SIZE)),
        transforms.ToTensor(),
        transforms.Normalize(MEAN, STD),
    ])

    data_dir = "./dataset"
    full_dataset = datasets.ImageFolder(data_dir, transform=eval_transform)
    _, _, test_idx = split_indices(len(full_dataset))
    test_loader = DataLoader(Subset(full_dataset, test_idx), batch_size=64, shuffle=False, num_workers=0)

    ckpt_path = "./checkpoints/mobilevit_best.pt"
    ckpt = torch.load(ckpt_path, map_location=device, weights_only=False)
    class_names = ckpt["class_names"]
    print(f"Loaded checkpoint epoch={ckpt.get('epoch')} val_acc={ckpt.get('val_acc',0)*100:.2f}%")

    model = timm.create_model("mobilevit_s", pretrained=False, num_classes=len(class_names))
    model.load_state_dict(ckpt["model_state"])
    model.to(device)
    model.eval()

    # 1. Standard evaluation
    correct = 0
    total = 0
    with torch.no_grad():
        for images, labels in test_loader:
            images, labels = images.to(device), labels.to(device)
            out = model(images)
            pred = out.argmax(dim=1)
            correct += (pred == labels).sum().item()
            total += labels.size(0)
    std_acc = correct / total
    print(f"Standard Test Acc: {std_acc*100:.2f}% ({correct}/{total})")

    # 2. Test-Time Augmentation (TTA: Original + Horizontal Flip)
    correct_tta = 0
    with torch.no_grad():
        for images, labels in test_loader:
            images, labels = images.to(device), labels.to(device)
            images_flip = torch.flip(images, dims=[3])
            
            p1 = F.softmax(model(images), dim=1)
            p2 = F.softmax(model(images_flip), dim=1)
            p_avg = (p1 + p2) / 2.0
            
            pred = p_avg.argmax(dim=1)
            correct_tta += (pred == labels).sum().item()
    tta_acc = correct_tta / total
    print(f"TTA (Flip) Test Acc: {tta_acc*100:.2f}% ({correct_tta}/{total})")

    # 3. Multi-Crop / Multi-Flip TTA
    # Original + H-Flip + V-Flip + H+V Flip
    correct_tta4 = 0
    with torch.no_grad():
        for images, labels in test_loader:
            images, labels = images.to(device), labels.to(device)
            images_h = torch.flip(images, dims=[3])
            images_v = torch.flip(images, dims=[2])
            images_hv = torch.flip(images, dims=[2, 3])
            
            p1 = F.softmax(model(images), dim=1)
            p2 = F.softmax(model(images_h), dim=1)
            p3 = F.softmax(model(images_v), dim=1)
            p4 = F.softmax(model(images_hv), dim=1)
            p_avg = (p1 + p2 + p3 + p4) / 4.0
            
            pred = p_avg.argmax(dim=1)
            correct_tta4 += (pred == labels).sum().item()
    tta4_acc = correct_tta4 / total
    print(f"TTA (4-Way Flip) Test Acc: {tta4_acc*100:.2f}% ({correct_tta4}/{total})")

if __name__ == "__main__":
    main()
