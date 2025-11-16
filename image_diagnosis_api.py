from flask import Flask, request, jsonify
import tensorflow as tf
import numpy as np
from PIL import Image
import io
import os
import keras # Explicitly import keras

app = Flask(__name__)

# Define the path to the converted SavedModel directory
MODEL_SAVEDMODEL_PATH = 'CropAPI/saved_model_converted'

# Load the TensorFlow model once when the app starts
try:
    # Check if the SavedModel directory exists
    if not os.path.exists(MODEL_SAVEDMODEL_PATH):
        raise FileNotFoundError(f"Model directory not found: {MODEL_SAVEDMODEL_PATH}")

    # Use keras.layers.TFSMLayer for loading SavedModel in Keras 3
    # The call_endpoint might vary, 'serving_default' is common.
    model_layer = keras.layers.TFSMLayer(MODEL_SAVEDMODEL_PATH, call_endpoint='serving_default')
    print(f"Successfully loaded model as TFSMLayer from {MODEL_SAVEDMODEL_PATH}")

    # Wrap the TFSMLayer in a Keras model for prediction if needed
    # For direct inference, you might call model_layer(input_tensor)
    # Here, we will make a simple model for compatibility with .predict()
    input_shape = (128, 128, 3) # Assuming your model expects 128x128x3 images
    model_input = keras.Input(shape=input_shape)
    model_output = model_layer(model_input)
    model = keras.Model(inputs=model_input, outputs=model_output)

except Exception as e:
    print(f"Error loading model from {MODEL_SAVEDMODEL_PATH}: {e}")
    model = None # Set model to None if loading fails

# Define Class names
class_name = [
    'Apple___Apple_scab',
    'Apple___Black_rot',
    'Apple___Cedar_apple_rust',
    'Apple___healthy',
    'Blueberry___healthy',
    'Cherry_(including_sour)___Powdery_mildew',
    'Cherry_(including_sour)___healthy',
    'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot',
    'Corn_(maize)___Common_rust_',
    'Corn_(maize)___Northern_Leaf_Blight',
    'Corn_(maize)___healthy',
    'Grape___Black_rot',
    'Grape___Esca_(Black_Measles)',
    'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)',
    'Grape___healthy',
    'Orange___Haunglongbing_(Citrus_greening)',
    'Peach___Bacterial_spot',
    'Peach___healthy',
    'Pepper,_bell___Bacterial_spot',
    'Pepper,_bell___healthy',
    'Potato___Early_blight',
    'Potato___Late_blight',
    'Potato___healthy',
    'Raspberry___healthy',
    'Soybean___healthy',
    'Squash___Powdery_mildew',
    'Strawberry___Leaf_scorch',
    'Strawberry___healthy',
    'Tomato___Bacterial_spot',
    'Tomato___Early_blight',
    'Tomato___Late_blight',
    'Tomato___Leaf_Mold',
    'Tomato___Septoria_leaf_spot',
    'Tomato___Spider_mites Two-spotted_spider_mite',
    'Tomato___Target_Spot',
    'Tomato___Tomato_Yellow_Leaf_Curl_Virus',
    'Tomato___Tomato_mosaic_virus',
    'Tomato___healthy'
]

@app.route('/predict', methods=['POST'])
def predict():
    if model is None:
        return jsonify({"error": "Model not loaded. Please ensure the model is available at the expected path."}), 500

    if 'file' not in request.files:
        return jsonify({"error": "No file part in the request"}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    if file:
        try:
            # Read the image file directly into PIL Image
            image = Image.open(io.BytesIO(file.read()))
            image = image.resize((128, 128)) # Resize to target size
            
            # Convert image to array, normalize (assuming model expects float32 and normalized data)
            input_arr = np.asarray(image).astype(np.float32) / 255.0 # Normalize to [0, 1]
            input_arr = np.expand_dims(input_arr, axis=0) # Add batch dimension

            prediction = model.predict(input_arr)
            # The output of TFSMLayer might be a dictionary or a list of tensors.
            # Assuming 'serving_default' produces a single tensor output.
            if isinstance(prediction, dict) and 'output_0' in prediction:
                prediction_values = prediction['output_0']
            else:
                prediction_values = prediction # Assume direct tensor output

            result_index = np.argmax(prediction_values)
            
            predicted_class = class_name[result_index]
            return jsonify({"prediction": predicted_class}), 200
        except Exception as e:
            return jsonify({"error": f"Error processing image or making prediction: {e}"}), 500

@app.route('/', methods=['GET'])
def home():
    return "Plant Disease Recognition API is running!"

if __name__ == '__main__':
    # For development, you can run on your local machine.
    # For deployment, you would typically use a production-ready WSGI server like Gunicorn.
    app.run(debug=True, host='0.0.0.0', port=5000)
