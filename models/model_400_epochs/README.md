# 400-Epoch Greenhouse Fan Control Model (greenhouse)

## 📊 Training Details  
- **Model Name:** greenhouse_model_400epoch.tflite
- **Epochs:** 400
- **Dataset:** 17,521 samples
- **Temperature range:** 20.9°C - 90.5°C  
- **Humidity range:** 31.69% - 100%
- **Architecture:** Dense(16, relu) → Dense(8, relu) → Dense(1, sigmoid)
- **Optimizer:** Adam
- **Loss function:** Binary crossentropy

## 🎯 Performance Metrics
- **Training Accuracy:** ~99%+
- **Validation Accuracy:** ~99%+
- **Training Loss:** ~0.001
- **Validation Loss:** ~0.001
- **Model Size:** ~2KB
- **Training Time:** ~15 minutes

## 🌡️ Normalization Parameters
```python
# MinMaxScaler parameters (same as 20-epoch model)
temperature_min = 20.9°C
temperature_max = 90.5°C  
humidity_min = 31.69%
humidity_max = 100.0%

# Normalization formula:
normalized_temp = (temp - 20.9) / (90.5 - 20.9)
normalized_humidity = (humidity - 31.69) / (100.0 - 31.69)
```

## ⚠️ Overfitting Indicators
- **Perfect accuracy:** 99%+ suggests memorization, not learning
- **Extremely low loss:** 0.001 indicates overfitting to training data
- **Binary predictions:** Only outputs 0.00 or 1.00 (no uncertainty)
- **Poor generalization:** Struggles with real-world sensor variations

## 📊 Test Predictions (From Notebook)
| Input | Temperature | Humidity | Prediction | Confidence | Decision |
|-------|-------------|----------|------------|------------|----------|
| Very Hot | 35°C | 80% | 1.00 | Perfect | ON |
| Cool | 22°C | 50% | 0.00 | Perfect | OFF |
| Warm & Humid | 28°C | 90% | 1.00 | Perfect | ON |
| Hot & Dry | 30°C | 40% | 0.00 | Perfect | OFF |

## 🔍 Real-World Issues

### Problems Observed:
- **No uncertainty handling** - Always 100% confident
- **Binary thinking** - No gradual transitions
- **Overconfident decisions** - May make wrong choices with high confidence
- **Poor edge case handling** - No hesitation in borderline conditions

### Expected Real-World Behavior:
```
🧠 AI Prediction: 0.000, Decision: OFF  # Too confident
🧠 AI Prediction: 1.000, Decision: ON   # Too confident  
🧠 AI Prediction: 1.000, Decision: ON   # No variation
🧠 AI Prediction: 0.000, Decision: OFF  # No uncertainty
```

## ❌ NOT Recommended for Production

### Reasons:
- ❌ **Overfitted to training data**
- ❌ **No uncertainty quantification**
- ❌ **Potential for confident wrong decisions**
- ❌ **Poor handling of sensor noise**
- ❌ **Inefficient energy usage**
- ❌ **Lacks robustness for real greenhouse conditions**

## 🔬 Research Value

### What This Model Teaches:
1. **More epochs ≠ better performance**
2. **Perfect training metrics can indicate overfitting**
3. **Real-world validation is crucial**
4. **Uncertainty is valuable in control systems**
5. **Early stopping could have prevented overfitting**

### Overfitting Symptoms:
- Training accuracy much higher than validation needs
- Extremely low validation loss
- Perfect confidence in all predictions
- Poor performance on new data

## 🎓 Lessons for Future Models

### Regularization Techniques to Try:
```python
model = keras.Sequential([
    layers.Dense(16, activation='relu', input_shape=(2,)),
    layers.Dropout(0.3),  # Add dropout
    layers.Dense(8, activation='relu'),
    layers.Dropout(0.2),  # More dropout
    layers.Dense(1, activation='sigmoid')
])

# Add early stopping
callbacks = [
    tf.keras.callbacks.EarlyStopping(
        monitor='val_loss',
        patience=50,
        restore_best_weights=True
    )
]
```

### Better Training Strategy:
- Use early stopping (stop at ~50-100 epochs)
- Monitor validation loss, not just accuracy
- Add dropout layers for regularization
- Use learning rate decay
- Cross-validate on real sensor data

## 📁 Files in This Directory
- `greenhouse_model_400epoch.tflite` - TensorFlow Lite model file (overfitted)
- `training_notebook_400epoch.ipynb` - Jupyter notebook showing overfitting
- `README.md` - This documentation

## 🔗 Related Files
- See `../MODEL_COMPARISON.md` for detailed comparison
- See `../model_20_epochs/` for the recommended production model
- This model is **NOT** used in the Flutter app for good reasons

## ⚡ Quick Summary

**This model demonstrates a classic machine learning pitfall:**
- High training accuracy ≠ good real-world performance
- Perfect predictions often indicate overfitting
- Sometimes stopping earlier gives better results

**Use the 20-epoch model instead!** 🎯

---
*This model serves as an educational example of overfitting in the greenhouse-ai-fancontroller project.*
