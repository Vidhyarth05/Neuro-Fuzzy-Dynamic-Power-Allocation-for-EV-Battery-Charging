# ⚡ Neuro-Fuzzy Dynamic Power Allocation for EV Battery Charging

## 🌟 Project Overview

This system presents a robust, Adaptive Neuro-Fuzzy Inference System (ANFIS) solution for **dynamic power allocation** in multi-battery Electric Vehicle (EV) charging stations. The core challenge is intelligently distributing a limited total station power capacity across heterogeneous battery packs with varying health and thermal characteristics.

The methodology addresses battery degradation risks and thermal safety margins by generating continuous, precise power allocation decisions in real-time.

### Key Features

- **Hybrid ANFIS Architecture:** Combines expert **Mamdani fuzzy rules** (for interpretability) with a **neural network** (for learning continuous, non-linear allocation functions)
- **Robust Feature Engineering:** Utilizes a dual-criterion framework to select **four orthogonal input features** from a 10-parameter dataset: **SOH, Charging Temperature, Discharge Temperature, and Internal Resistance Proxy**
- **Hierarchical Allocation Algorithm:** A real-time O(N) algorithm that respects **individual battery safety limits (P_max,i)** and the **total station capacity (P_total)** simultaneously
- **High Performance:** The trained 16-rule ANFIS model achieves **R² = 0.8835** and **RMSE = 3.75%** on the validation set, demonstrating strong generalization

---

## ⚙️ System Workflow & Methodology

The project is structured into three main scripts, following the hybrid neuro-fuzzy pipeline.

### 1. Data Preparation and Fuzzy Labeling (`First.m`)

- **Purpose:** Clean the raw battery cycling data, engineer the Internal Resistance Proxy (IR_proxy = V_ch / (I_ch + ε)), and synthesize the target labels
- **Fuzzy Expert System:** A **Mamdani FIS** with SOH and Charging Temperature inputs is used to encode expert knowledge into nine IF-THEN rules (e.g., *IF SOH is Poor AND T_ch is Hot THEN PowerAllocationFactor is Slow*)
- **Output:** Generates `Smart_Allocation_Fuzzy_Labels.csv` and parameter files needed for training

### 2. ANFIS Training and Evaluation (`second.m`)

- **Purpose:** Train the ANFIS model to learn the continuous function underlying the fuzzy-generated labels
- **Architecture:** Uses **Grid Partitioning** with **2 Generalized Bell Membership Functions** per input, resulting in a **16-rule, five-layer ANFIS structure**
- **Training:** Employs a **Hybrid Learning Algorithm** (Least Squares + Backpropagation) for 150 epochs
- **Output:** Generates comprehensive performance plots (Convergence, Scatter, Rule Surfaces) and saves the trained model (`Smart_Allocation_Trained_ANFIS.fis`)

### 3. Real-Time Allocation GUI (`Third.m`)

- **Purpose:** Provides an interactive MATLAB GUI for multi-battery power distribution based on the trained ANFIS model
- **Allocation Logic:** Implements the **Two-Step Hierarchical Constraint Satisfaction**:
  1. **Desired Power:** P_desired,i = ANFIS_Score × P_max,i
  2. **Station Constraint:** If total desired power exceeds station capacity, all allocations are scaled down proportionally

---

## 🏃 Getting Started

### Prerequisites

- **MATLAB** (Required for all scripts)
- **Fuzzy Logic Toolbox** (Required for all scripts)
- A CSV file named `Battery_dataset.csv` (Raw battery cycling data)

### Execution Steps

1. **Run Data and Label Generation:**
   ```matlab
   >> First
   ```
   *This creates the fuzzy labels and selects the final 4 features.*

2. **Run ANFIS Training:**
   ```matlab
   >> second
   ```
   *This trains the model, performs evaluation, and saves the final FIS model.*

3. **Run Interactive Allocation GUI:**
   ```matlab
   >> Third
   ```
   *The GUI will open, allowing you to input battery parameters and total station power to see the resulting smart power allocation.*

---

## 🔬 Technical Details

### Feature Engineering

The system intelligently selects four key features from the battery dataset:

1. **State of Health (SOH):** Indicates battery degradation level
2. **Charging Temperature:** Current temperature during charging phase
3. **Discharge Temperature:** Temperature during previous discharge cycle
4. **Internal Resistance Proxy:** Calculated ratio of voltage to current

### ANFIS Architecture

The Adaptive Neuro-Fuzzy Inference System consists of five layers:

1. **Layer 1 (Fuzzification):** Converts crisp inputs to fuzzy membership values
2. **Layer 2 (Rule Layer):** Computes firing strength of each rule
3. **Layer 3 (Normalization):** Normalizes firing strengths
4. **Layer 4 (Defuzzification):** Computes rule outputs
5. **Layer 5 (Aggregation):** Produces final crisp output

### Power Allocation Algorithm

```
For each battery i:
  1. Calculate ANFIS score based on input features
  2. Compute desired power: P_desired,i = score × P_max,i
  3. Sum all desired powers: P_sum = Σ P_desired,i
  
If P_sum > P_total:
  For each battery i:
    P_allocated,i = P_desired,i × (P_total / P_sum)
Else:
  P_allocated,i = P_desired,i
```

---

## 📊 Performance Metrics

| Metric | Value | Interpretation |
|:-------|:------|:---------------|
| **R² Score** | 0.8835 | Strong correlation between predicted and actual values |
| **RMSE** | 3.75% | Low prediction error |
| **Number of Rules** | 16 | Compact, interpretable rule base |
| **Training Epochs** | 150 | Efficient convergence |

---

## 🎯 Use Cases

- Multi-bay EV charging stations
- Fleet charging management
- Battery health-aware charging systems
- Thermal safety-critical applications
- Smart grid integration for EVs

---

## 📁 Project Structure

```
├── First.m                           # Data preparation and fuzzy labeling
├── second.m                          # ANFIS training and evaluation
├── Third.m                           # Real-time allocation GUI
├── Battery_dataset.csv               # Input: Raw battery cycling data
├── Smart_Allocation_Fuzzy_Labels.csv # Generated: Labeled dataset
└── Smart_Allocation_Trained_ANFIS.fis # Generated: Trained model
```

---

## 🔧 Configuration Options

### Fuzzy Rule Customization

You can modify the Mamdani fuzzy rules in `First.m` to reflect different expert knowledge or charging strategies.

### ANFIS Parameters

Key parameters that can be tuned in `second.m`:
- Number of membership functions per input
- Type of membership function (Gaussian, Trapezoidal, etc.)
- Training epochs
- Learning rate

### GUI Customization

The interactive GUI in `Third.m` can be extended to include:
- Real-time monitoring displays
- Historical allocation logs
- Battery health trending

---


