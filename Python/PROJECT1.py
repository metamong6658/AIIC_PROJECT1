################### Description ###################
## This Model pre-processed 'Dog-cat data set' for binary data(0,1)
## This Model focused on less Total Params as possible(351041)
## Short layer Architecture gets 95~99% accuracy for test data set
## What's implemented: 
## Train, Test(Predict), 
## Gets Quantize factor for RTL implementation, 
## Save parameters(Weights, Test data) for RTL implementation 
## Printed Check Factor, You can get parameters for RTL Sigmoid by Shift-add method implementation
## Please Contact metamong6658@gmail.com 
## Data : 2022-10-25
################### Pacakage ###################
import numpy as np
import pandas as pd
import cv2
import matplotlib.pyplot as plt
import random
import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'
import tensorflow as tf
import zipfile
from turtle import shape
from tensorflow.python.keras import Model
from tensorflow.python.keras.models import Sequential
from tensorflow.python.keras.layers import Dense, Flatten, Dropout, Activation, Conv2D, MaxPooling2D
################### Extract Zip file ###################
with zipfile.ZipFile("./train.zip","r") as z:
    z.extractall(".")

with zipfile.ZipFile("./test1.zip", "r") as z:
    z.extractall(".")
################### Train and Pre-processing ###################
main_dir = "./"
train_dir = "train/"
path = os.path.join(main_dir,train_dir)

X = []
y = []
convert = lambda category : int(category == 'dog')
def create_train_data(path):
    for p in os.listdir(path):
        category = p.split(".")[0]
        category = convert(category)
        img_array = cv2.imread(os.path.join(path,p),cv2.IMREAD_GRAYSCALE)
        new_img_array = cv2.resize(img_array, dsize=(58,58))
        X.append(new_img_array)
        y.append(category)

create_train_data(path)
X = np.array(X).reshape(-1,58,58,1)
y = np.array(y)
# Binary Quantize Input data
X = X/128
X = X.astype(int)
# Quantized Random Binary Image Plot
index = random.randint(0,25000)
plt.imshow(X[index])
################### Model ###################
# input layer
input_layer = tf.keras.layers.InputLayer(input_shape=X.shape[1:])
# layer1
layer_conv1 = tf.keras.layers.Conv2D(16,(3,3),activation='relu')
pool1 = tf.keras.layers.MaxPool2D(pool_size=(2,2))
# layer2
layer_conv2 = tf.keras.layers.Conv2D(32,(3,3),activation='relu')
pool2 = tf.keras.layers.MaxPool2D(pool_size=(2,2))
# flatten layer
layer_flatten = tf.keras.layers.Flatten()
# layer3
layer_dense = tf.keras.layers.Dense(64,activation='relu')
# output layer
output_layer = tf.keras.layers.Dense(1,activation='sigmoid')

model = tf.keras.Sequential([
    input_layer,
    layer_conv1,
    pool1,
    layer_conv2,
    pool2,
    layer_flatten,
    layer_dense,
    output_layer
])
model.compile(optimizer="Adam", loss = 'mse', metrics = ['accuracy'])
model.fit(X,y,epochs=10,batch_size=32,validation_split=0.2)
model.summary()
################### Find Maximum value of Activations ###################
intermediate_layer_model = tf.keras.Model(inputs=model.input, outputs = model.layers[5].output)
intermediate_output = intermediate_layer_model(X) # tensor
intermediate_output_numpy = intermediate_output.numpy()
maximum_firstdense = 0
for inter in intermediate_output_numpy:
    if maximum_firstdense < max(abs(inter)):
        maximum_firstdense = max(abs(inter))
################### Test(predict) ###################
test_dir = "test1/"
path = os.path.join(main_dir,test_dir)

X_test = []
id_line = []

def create_test1_data(path):
    for p in os.listdir(path):
        id_line.append(p.split(".")[0])
        img_array = cv2.imread(os.path.join(path,p),cv2.IMREAD_GRAYSCALE)
        new_img_array = cv2.resize(img_array,dsize=(58,58))
        X_test.append(new_img_array)

create_test1_data(path)
X_test = np.array(X_test).reshape(-1,58,58,1)
X_test = X_test/128
X_test = X_test.astype(int)

predictions = model.predict(X_test)
predicted_val = [int(round(p[0])) for p in predictions]
submission_df = pd.DataFrame({'id':id_line, 'label':predicted_val})
submission_df.to_csv("PredictResult.csv", index=False)
################### Weight Extraction from Each Layer and Find Maximum Value of Weight ###################
Weight_layer1 = layer_conv1.get_weights()[0]
Weight_layer1 = np.array(Weight_layer1)
list_layer1 = []
for i in Weight_layer1:
    for k in range(16):
        for j in i:
            list_layer1.append(j[0][k])
weight_list1 = np.array([list_layer1]) # It will be Qauntized

Weight_layer2 = layer_conv2.get_weights()[0]
Weight_layer2 = np.array(Weight_layer2)
list_layer2 = []
for i in Weight_layer2:
    for k in range(32):
        for j in i:
            list_layer2.append(j[0][k])
weight_list2 = np.array([list_layer2]) # It will be Quantized

Weight_layer3 = layer_dense.get_weights()[0]
Weight_layer3 = np.array(Weight_layer3)
list_layer3 = []
for i in range(64):
    for j in Weight_layer3:
        list_layer3.append(j[i])
weight_list3 = np.array([list_layer3]) # It will be Quantized

Weight_layer4 = output_layer.get_weights()[0]
Weight_layer4 = np.array(Weight_layer4)
list_layer4 = []
for i in Weight_layer4:
    list_layer4.append(i[0])
weight_list4 = np.array([list_layer4]) # It will be Quantized

max_weight_list = []
list_layer1 = list(map(abs,list_layer1))
list_layer2 = list(map(abs,list_layer2))
list_layer3 = list(map(abs,list_layer3))
list_layer4 = list(map(abs,list_layer4))
max_weight1 = max(list_layer1)
max_weight2 = max(list_layer2)
max_weight3 = max(list_layer3)
max_weight4 = max(list_layer4)

max_weight_list.append(max_weight1)
max_weight_list.append(max_weight2)
max_weight_list.append(max_weight3)
max_weight_list.append(max_weight4)

max_weight = 0
for i in max_weight_list:
    if i > max_weight:
        max_weight = i
################### For Check Maximum Value ###################
print("----------------- Maximum Value -----------------")
print(f"Maximum Activations:\t{maximum_firstdense}")
print(f'Maximum Weight:\t{max_weight}')
################### Quantization ###################
Qa = 255/maximum_firstdense # Quantization facotr for Activation - signed 8bits
Qw = 127/max_weight # Quantization factor for Weight - signed 8bits

# For Weight
weight_list1 = np.around(weight_list1*Qw)
weight_list2 = np.around(weight_list2*Qw)
weight_list3 = np.around(weight_list3*Qw)
weight_list4 = np.around(weight_list4*Qw)

weight_list1 = weight_list1.astype(int)
weight_list2 = weight_list2.astype(int)
weight_list3 = weight_list3.astype(int)
weight_list4 = weight_list4.astype(int)

# For Sigmoid by Shift-add method 
lower_bound = np.array([[0.0, 1.065, 2.164, 2.977, 3.724, 4.442, 5.147, 5.846, 7.236]])
constant = np.array([[0.5, 0.6328125, 0.765625, 0.859375, 0.91796875, 0.953125, 0.97265625, 0.984375, 1.0]])
sigmoid_max = np.array([[1.0]])

lower_bound = np.around(Qa*Qw*lower_bound) # signed 32 bits
constant = np.around(Qa*Qw*constant) # signed 32 bits
sigmoid_max = np.around(Qa*Qw*sigmoid_max) # signed 32 bits

lower_bound = lower_bound.astype(int)
constant = constant.astype(int)
sigmoid_max = sigmoid_max.astype(int)

# For Test data in RTL
print("----------------- Check RTL data -----------------")
numOftest = 20 # You can change how many sample you test
test_data = X_test[:numOftest]
list_data = []
for data in test_data:
    for row in data:
        for col in row:
            list_data.append(col[0])
list_data = np.array([list_data])
list_data = np.around(list_data*Qa)
list_data = list_data.astype(int)
print(f'test_data.shape:{test_data.shape}')
print(f'list_data.shape:{list_data.shape}')
################### For Check Quantization Parameter ###################
print("----------------- Check Factor -----------------")
print(f'Qw:\t{Qw}')
print(f'Qa:\t{Qa}')
print(f'sigmoid_max:{sigmoid_max}')
print(f'lower_bound:\n{lower_bound}')
print(f'constant:\n{constant}')
################### Save Parameter for text file ###################
def tohex(val,nbits):
    return ((val+(1<<nbits))%(1<<nbits))

print("----------------- Check Shape -----------------")
print(f"list_layer1: {weight_list1.shape}")
print(f"lower_bound: {lower_bound.shape}")
print(f"sigmoid_max: {sigmoid_max.shape}")

# Weight - signed int 8bits
f = open('../Verilog/weights_layer1.hex','w')
for i in weight_list1.T:
    for j in i:
        f.write("%02x\n" %tohex(j,8))
f.close()

f = open('../Verilog/weights_layer2.hex','w')
for i in weight_list2.T:
    for j in i:
        f.write("%02x\n" %tohex(j,8))
f.close()

f = open('../Verilog/weights_layer3.hex','w')
for i in weight_list3.T:
    for j in i:
        f.write("%02x\n" %tohex(j,8))
f.close()

f = open('../Verilog/weights_layer4.hex','w')
for i in weight_list4.T:
    for j in i:
        f.write("%02x\n" %tohex(j,8))
f.close()

# Test data - unsigned int 8bits
f = open('../Verilog/RTL_test_data.hex','w')
for i in list_data.T:
    for j in i:
        f.write("%02x\n" %tohex(j,8))
f.close()
################### Plot Quantized Binary Image ###################
print("----------------- Check Plot -----------------")
plt.show()