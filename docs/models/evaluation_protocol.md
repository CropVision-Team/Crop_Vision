# CropVision evaluation protocol

## What the supplied test result shows

The supplied `mobilevit_best.pt` result is **98.56% accuracy (10,555 / 10,709)** on `official_test`. This is a useful in-distribution estimate, but it is not evidence that the system works on arbitrary phone photos in fields. The old checkpoint is a single disease-class head; it does not independently predict the crop.

The most informative class results from the supplied output are:

| True class | Recall | Largest recorded error |
| --- | ---: | --- |
| Tomato late blight | 91.5% (32 / 375 wrong) | 27 predicted as grape Esca |
| Corn northern leaf blight | 89.1% (24 / 220 wrong) | 24 predicted as corn cercospora / gray leaf spot |
| Corn common rust | 95.9% (9 / 217 wrong) | 6 predicted as grape Esca |
| Tomato yellow leaf curl virus | 96.5% (38 / 1,100 wrong) | 24 predicted as tomato bacterial spot |

So tomato late blight is genuinely lower than the overall result. Corn common rust is slightly below the overall result but not a severe failure in this particular checkpoint; an earlier checkpoint in the pasted log had only 88.0% recall, which demonstrates that checkpoint selection matters.

The repeated errors are late blight -> grape Esca, northern leaf blight -> gray leaf spot, yellow leaf curl -> bacterial spot, and common rust -> grape Esca. The grape confusions cross crop boundaries; that is exactly the failure mode a separate crop head and crop-aware rejection should address.

## Required checks before reporting a headline score

Run the leakage audit before every final training run:

```powershell
cd model
python .\audit_dataset.py --train_dir .\dataset --test_dir .\official_test --output_dir .\dataset_audit
```

Do not call the split independent if `exact_duplicates.csv` contains rows. Inspect every candidate in `near_duplicates.csv` visually, then move every confirmed duplicate group to one split and train again. A dHash match is a conservative candidate signal, not proof by itself. `cross_split_exif_groups.csv` is a warning only: EXIF is often removed, so a clean report cannot prove source independence. For a defensible result, create a manifest containing `source_id`, `field_id`, `plant_id`, and `capture_session_id`, then split by that group rather than by image.

## Field-phone benchmark

Collect a held-out, labelled `field_test` folder with the same class folders as `official_test`, never using photos from a plant/session represented in training. Balance at least these strata for the weak classes: morning/midday/shade, clear/complex background, near/far framing, blur, and at least two phone models. Keep a CSV manifest with the image path and those fields so performance can be reported by condition.

Run the current model against it only after it has been frozen:

```powershell
python .\evaluate_test.py --checkpoint .\checkpoints\mobilevit_best.pt --split_dir .\field_test
python .\evaluate_test.py --checkpoint .\checkpoints\mobilevit_best.pt --split_dir .\field_test --known_crop
```

`--known_crop` is an oracle ablation: it answers how well disease recognition works *if the farmer selects the correct crop*. It must not be presented as the normal automatic-crop score.

## Training and tuning status

There are two training paths in this repository. `train_mobilevit.py` produced the supplied single-head checkpoint. It already includes geometric, brightness, blur, noise and perspective augmentation, but there is no committed hyperparameter-search result proving that its settings are optimal.

`train_cropvision.py` is the stronger path. It adds ImageNet pretraining, AdamW, warm-up/cosine learning rate, label smoothing, EMA, early stopping, a crop head, hierarchical crop/disease consistency loss, optional outlier exposure and a separate official-test evaluation. It now also applies camera/lighting augmentation. Use that path for the next candidate and compare candidates on the same untouched field test; do not tune on the final field test.

Its final evaluation prints `CROP HEAD ACCURACY` and writes a crop confusion matrix; that is the metric to use for crop recognition. The inference server also accepts either checkpoint format. To serve a hierarchical checkpoint and return `predicted_crop` plus `crop_confidence` in the API response:

```powershell
$env:CROPVISION_CHECKPOINT = '.\runs\mobilevit_hier\mobilevit_s_cropvision_best.pt'
python .\inference_server.py
```

Example candidate run:

```powershell
python .\audit_dataset.py --train_dir .\dataset --test_dir .\official_test
python .\train_cropvision.py --data_dir .\dataset --test_dir .\official_test --backbone mobilevit_s --epochs 30 --batch_size 32 --output_dir .\runs\mobilevit_hier
```

No current repository artifact demonstrates outdoor generalization, nor can crop identification be claimed reliable for the supplied single-head checkpoint. The hierarchical trainer is designed to measure and improve this, but it must be trained and evaluated on a held-out field set first.
