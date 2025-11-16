from tensorflow import keras
import tensorflow as tf
import sys
import os
import traceback

MODEL_PATH = "trained_model.h5"   # your file
OUT_DIR = "saved_model_converted"

print("TF version:", tf.__version__)
if not os.path.exists(MODEL_PATH):
    print("Model file not found at", MODEL_PATH)
    sys.exit(1)

try:
    print("Trying to load model with compile=False ...")
    model = keras.models.load_model(MODEL_PATH, compile=False)
    print("Loaded model OK.")
    print("Saving as TensorFlow SavedModel to", OUT_DIR)
    # Use tf.saved_model.save instead of model.save with save_format="tf"
    tf.saved_model.save(model, OUT_DIR)
    print("SavedModel written to", OUT_DIR)
except Exception:
    print("Failed to load or save model. Exception:")
    traceback.print_exc()
    sys.exit(2)
