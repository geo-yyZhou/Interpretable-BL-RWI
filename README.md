# Interpretable-BL-RWI
Interpretable broad learning Rayleigh wave inversion framework

## Overview

This code package implements the method proposed in the paper:

> **"Interpretable Rayleigh Wave Inversion Framework and Its Practical Implications"**  
> *Submitted to Journal of Applied Geophysics*
> Authors: Yuanyuan Zhou, Xiao-Hui Yang, Peng Han*, Katsumi Hattori*, Ruidong Li, Bingbing Han, Wuhu Zhang, Xiaofei Chen

The package provides a complete workflow for multi-mode Rayleigh wave dispersion inversion using a Broad Learning network, with frequency-point importance quantification for interpretability.

---

## Quick Start

Run the main script directly in MATLAB:

```matlab
main_invImportanceQuant.m
```

No additional configuration is required before running.

---

## File Description

### Main Script
| File | Description |
|------|-------------|
| `main_invImportanceQuant.m` | Entry point. Runs the full inversion and importance quantification workflow. |

### Example Data
The following files provide a synthetic numerical example with three dispersion curve modes:

| File | Description |
|------|-------------|
| `uniformDis_fun.xlsx` | Fundamental mode dispersion curve |
| `uniformDis_1st.xlsx` | First higher mode dispersion curve |
| `uniformDis_2nd.xlsx` | Second higher mode dispersion curve |
| `Vs_profile_true.xls` | True earth model parameters (staircase Vs profile) for validation |

### Broad learning Core Functions (3 variants)
Each variant consists of a regression wrapper and a training subfunction:

| Variant | Files | Use case |
|---------|-------|----------|
| Baseline | `bls_regression_sub_noTest.m` / `bls_train_noTest.m` | Standard single-sample inversion |
| Importance | `bls_regression_sub_noTest_importance.m` / `bls_train_noTest_importance.m` | Error evaluated on high-importance frequency points only |
| Matrix input | `bls_regression_sub_noTest_matrixTestInput.m` / `bls_train_noTest_matrixTestInput.m` | Batch prediction for multiple samples simultaneously |

---

## Citation

If you use this code in your research, please cite the associated paper:

> "Yuanyuan Zhou, Xiao-Hui Yang, Peng Han*, Katsumi Hattori*, Ruidong Li, Bingbing Han, Wuhu Zhang, Xiaofei Chen. Interpretable Rayleigh Wave Inversion Framework and Its Practical Implications. Submitted to Journal of Applied Geophysics"
