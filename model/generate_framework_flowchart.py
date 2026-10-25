"""
Generate publication-quality Fig. 1 Flowchart and framework diagram for CropVision.
Matches the academic style of friend's Fig. 1, with flawless layout, perfect routing,
clean typography, and no text overlaps.
"""
from pathlib import Path
import matplotlib.pyplot as plt
import matplotlib.patches as patches

OUT_DIR = Path("../docs/research_figures")
OUT_DIR.mkdir(parents=True, exist_ok=True)


def draw_box(ax, x, y, w, h, text, title=None, subitems=None, color="#f1f5f9", edge_color="#334155", box_style="round,pad=0.2"):
    p = patches.FancyBboxPatch((x, y), w, h, boxstyle=box_style,
                               facecolor=color, edgecolor=edge_color, linewidth=1.5, zorder=2)
    ax.add_patch(p)
    if title:
        ax.text(x + w / 2, y + h - 0.22, title, ha="center", va="top",
                fontsize=9.5, fontweight="bold", color="#0f172a", zorder=3)
    if text:
        ax.text(x + w / 2, y + h / 2 if not title else y + h / 2 - 0.08, text, ha="center", va="center",
                fontsize=8.5, color="#1e293b", zorder=3)
    if subitems:
        start_y = y + h - 0.45
        for i, item in enumerate(subitems):
            sw, sh = w * 0.88, 0.32
            sx = x + (w - sw) / 2
            sy = start_y - i * 0.38
            sp = patches.FancyBboxPatch((sx, sy), sw, sh, boxstyle="round,pad=0.08",
                                        facecolor="#ffffff", edgecolor="#94a3b8", linewidth=1.0, zorder=3)
            ax.add_patch(sp)
            ax.text(sx + sw / 2, sy + sh / 2, item, ha="center", va="center",
                    fontsize=8.0, color="#334155", zorder=4)


def draw_cylinder(ax, x, y, r, h, text, color="#f8fafc", edge_color="#334155"):
    top = patches.Ellipse((x + r, y + h), 2 * r, 0.28, facecolor="#e2e8f0", edgecolor=edge_color, linewidth=1.5, zorder=3)
    rect = patches.Rectangle((x, y), 2 * r, h, facecolor=color, edgecolor=edge_color, linewidth=1.5, zorder=2)
    bottom = patches.Ellipse((x + r, y), 2 * r, 0.28, facecolor=color, edgecolor=edge_color, linewidth=1.5, zorder=2)
    ax.add_patch(rect)
    ax.add_patch(bottom)
    ax.add_patch(top)
    ax.text(x + r, y + h / 2, text, ha="center", va="center", rotation=90, fontsize=8.5, fontweight="bold", color="#1e293b", zorder=4)


def draw_arrow(ax, x1, y1, x2, y2, label=None, label_offset=(0, 0.1), color="#334155"):
    ax.annotate("", xy=(x2, y2), xytext=(x1, y1),
                arrowprops=dict(arrowstyle="-|>", color=color, lw=1.4, mutation_scale=12), zorder=1)
    if label:
        lx = (x1 + x2) / 2 + label_offset[0]
        ly = (y1 + y2) / 2 + label_offset[1]
        ax.text(lx, ly, label, ha="center", va="center", fontsize=7.5, color="#475569",
                backgroundcolor="#ffffff", zorder=5)


def generate_flowchart():
    fig, ax = plt.subplots(figsize=(14.0, 9.6))
    ax.set_xlim(0, 14.0)
    ax.set_ylim(0, 9.6)
    ax.axis("off")

    # 1. Dataset Cylinder
    draw_cylinder(ax, 0.5, 7.3, 0.45, 1.3, "PlantVillage\n& Field Dataset\n(54,305 Images)")

    # 2. Data Cleaning & Preprocessing Block
    draw_box(ax, 1.9, 6.9, 2.5, 1.8, None, title="Data Audit & Preprocessing",
             subitems=["dHash Leakage Audit", "Stratified 3-Way Split", "Resizing & Normalization"],
             color="#f1f5f9")
    draw_arrow(ax, 1.4, 7.95, 1.9, 7.95)

    # 3. Data Augmentation
    draw_box(ax, 4.9, 7.35, 1.9, 1.2, "Conservative\nAugmentation\n(Jitter, Rot, Blur)",
             color="#ffffff")
    draw_arrow(ax, 4.4, 7.95, 4.9, 7.95)

    # 4. Model Building
    draw_box(ax, 7.3, 7.15, 2.4, 1.55, None, title="Model Training Engine",
             subitems=["MobileViT-Small Backbone", "Dual-Head (14 Crop/38 Dis)", "Hierarchical Loss + EMA"],
             color="#f1f5f9")
    draw_arrow(ax, 6.8, 7.95, 7.3, 7.95)

    # 5. Saved PyTorch Model
    draw_box(ax, 10.3, 7.35, 2.1, 1.25, "Saved Model\n(mobilevit_best.pt)\n98.56% Accuracy",
             color="#eff6ff", edge_color="#2563eb")
    draw_arrow(ax, 9.7, 7.95, 10.3, 7.95)

    # 6. Performance Evaluation (Positioned to the right of Saved Model)
    draw_box(ax, 10.3, 5.3, 2.1, 1.25, "Performance Evaluation\n(Confusion Matrix & F1\nAcross 14 Crops)",
             color="#f8fafc")
    draw_arrow(ax, 11.35, 7.35, 11.35, 6.55)

    # 7. Model Optimization / Quantization Branch
    # Path A: Cloud PyTorch / FastAPI
    draw_box(ax, 10.3, 3.2, 2.1, 1.35, None, title="Cloud Model Serving",
             subitems=["PyTorch Cloud Engine", "FastAPI ASGI Cluster"], color="#f1f5f9")
    draw_arrow(ax, 11.35, 5.3, 11.35, 4.55, label="Cloud Serving", label_offset=(0.6, 0))

    # Path B: On-Device TFLite INT8 Quantization (Cleanly positioned in middle column)
    draw_box(ax, 6.3, 4.2, 2.5, 1.4, None, title="Post-Training Quantization",
             subitems=["INT8 PTQ Quantization", "TFLite / ONNX Model (5.8MB)"],
             color="#ecfdf5", edge_color="#059669")
    
    # Route arrow from Saved Model to PTQ Quantization
    ax.plot([10.3, 8.8, 8.8], [7.7, 7.7, 5.6], color="#334155", lw=1.4, zorder=1)
    draw_arrow(ax, 8.8, 5.6, 8.8, 5.6)
    draw_arrow(ax, 8.8, 5.6, 8.0, 5.6)
    ax.text(8.8, 6.7, "PTQ Full INT8\nQuantization", ha="center", va="center", fontsize=7.5,
            color="#047857", fontweight="bold", backgroundcolor="#ffffff", zorder=5)

    # 8. Cloud Telemetry & PostGIS Gateway
    draw_box(ax, 10.1, 1.1, 2.5, 1.5, None, title="Supabase Cloud Tier",
             subitems=["PostgreSQL 15 + RLS", "PostGIS Spatial Clusters", "Disease Outbreak Telemetry"],
             color="#faf5ff", edge_color="#9333ea")
    draw_arrow(ax, 11.35, 3.2, 11.35, 2.6)

    # 9. Edge Mobile Client (Flutter)
    draw_box(ax, 0.5, 0.9, 4.5, 5.1, None, title="Mobile Client (Flutter Application - Android/iOS)",
             subitems=[
                 "Camera Viewfinder / Gallery Picker",
                 "Image Quality Gate (Laplacian Blur >= 100)",
                 "Leaf Verification Gate (HSV Ratio >= 18%)",
                 "On-Device TFLite Engine (Offline <45ms)",
                 "HSV Lesion Severity Grading (G0-G3)",
                 "Stage-Based FRAC Agronomic Advisory",
                 "Crop Growth Stage Calendar Tracker",
                 "Offline SQLite DB & Cloud Sync"
             ],
             color="#f8fafc", edge_color="#0f172a")

    # Connect TFLite to Mobile Client
    draw_arrow(ax, 6.3, 4.9, 5.0, 4.9, label="Embedded On-Device\n(Zero-Bandwidth Offline)", label_offset=(0, 0.22))

    # Connect Cloud to Mobile Client
    draw_arrow(ax, 10.1, 1.85, 5.0, 1.85, label="Periodic Sync / Telemetry (WiFi / 4G)", label_offset=(0, 0.18))

    # Title label at bottom
    ax.text(7.0, 0.35, "Fig. 1. Flowchart and framework for crop leaf disease detection, verification, severity grading, and advisory in CropVision.",
            ha="center", va="center", fontsize=10.5, fontweight="bold", color="#0f172a")

    plt.tight_layout()
    out_file = OUT_DIR / "system_framework_flowchart.png"
    plt.savefig(out_file, dpi=300)
    plt.close()
    print(f"Clean framework flowchart saved to {out_file.resolve()}")

if __name__ == "__main__":
    generate_flowchart()
