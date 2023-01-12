# -*- coding: utf-8 -*-
"""
Created on Sun Oct 31 14:53:06 2021

@author: Adam
"""
#%%
import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from keras.models import load_model
from PIL import Image
from skimage.transform import resize


# =================== THESE ARE THE VARIABLES ====================== #
#INPUT_FOLDER_PATH = r"C:\Users\Kaining\Dropbox\Root length estimation - Copy\Trail images for root length estimation"
INPUT_FOLDER_PATH = r"C:\Users\Kaining\Dropbox\Apps\RootCamPy\cam1\L00"
#OUTPUT_PREDICTIONS_PATH = r"C:\Users\Kaining\Dropbox\Root length estimation - Copy\RLD estimation_20221116.csv"
OUTPUT_PREDICTIONS_PATH = r"C:\Users\Kaining\Dropbox\daily\TRL.csv"
MODEL_PATH = r"C:\Users\Kaining\Dropbox\daily\weekend_v2.h5"



#%%

H = 156
W = 212
MODEL_BINS = np.array([
   0.       ,  3.58,  8.44 , 13.35, 18.45 ,
   25.33 , 32.38, 41.65 , 52.59, 68.45 , 100
])

assert(os.path.isdir(INPUT_FOLDER_PATH))
assert(OUTPUT_PREDICTIONS_PATH.endswith(".csv"))
assert(MODEL_PATH.endswith(".h5"))
assert(os.path.isfile(MODEL_PATH))
assert(all([(vl < vr) for vl, vr in zip(MODEL_BINS, MODEL_BINS[1:])]))

def get_df_of_file_names_to_predict_on(INPUT_FOLDER_PATH):
    filenames = os.listdir(INPUT_FOLDER_PATH)
    image_paths = [
            os.path.join(INPUT_FOLDER_PATH, fname)
            for fname in filenames if 
            fname.endswith('.png') or 
            fname.endswith('.jpeg') or 
            fname.endswith('.jpg')]
    
    image_names = [
            fname
            for fname in filenames if 
            fname.endswith('.png') or 
            fname.endswith('.jpeg') or 
            fname.endswith('.jpg')]
    
    toPredict = pd.DataFrame({"filename":image_paths, 
                              "image_name":image_names})
    toPredict["pred_len"] = -1
    toPredict["pred_cls"] = -1
    toPredict["classes_agree"] = -1
    toPredict["lengths_agree"] = -1
    return toPredict    

print("Assertions passed, loading model..")
topred = get_df_of_file_names_to_predict_on(INPUT_FOLDER_PATH)
print(INPUT_FOLDER_PATH)
print(MODEL_PATH)
model = load_model(MODEL_PATH)
#%%
classes_agree_col = np.where(topred.columns == "classes_agree")[0]
lengths_agree_col = np.where(topred.columns == "lengths_agree")[0]
pred_cls_col = np.where(topred.columns == "pred_cls")[0]
pred_len_col = np.where(topred.columns == "pred_len")[0]

print("Testing loop....")
for i in range(np.min([5,len(topred)])):
    print(f"image {i}: - ", end="")
    try:
        impath = topred.iloc[i,:]['filename']
        
        im = np.array(Image.fromarray(plt.imread(impath)).resize((W,H)))
        im1 = np.expand_dims(im, 0)
        im2 = np.expand_dims(np.flipud(im), 0)
        p1 = model.predict(im1)
        p2 = model.predict(im2)
        
        clss1 = np.argmax(p1[0])
        clss2 = np.argmax(p2[0])
        len1 = p1[1][0][0]
        len2 = p2[1][0][0]
        
        if( np.max(p1[0]) > np.max(p2[0]) ):
            clssf = clss1
            lenf = len1
        else:
            clssf = clss2
            lenf = len2
        
        if(clss1 == clss2):
            topred.iloc[i, classes_agree_col] = 1    
        if( np.abs(len1 - len2)/np.max([len1, len2]) <= 0.2 ):
            topred.iloc[i, lengths_agree_col] = 1    
        
        topred.iloc[i, pred_cls_col] = clssf
        topred.iloc[i, pred_len_col] = lenf
        print(f"Passed!", end="\n")
    except:
        print(f"Failed!", end="\n")
        exit(0)
print()    
print("=========================================================")
print("     All Tests Passed, starting main loop")
print("=========================================================")
#%%
print("Running Main Loop:")
for i in range(len(topred)):
    if(i > 0 and i % 5 == 0):
        print("{:3.2f}% Done".format(100*np.round(i/len(topred),2)) )
        
    impath = topred.iloc[i,:]['filename']
    im1 = np.expand_dims(resize(plt.imread(impath), [H,W]), 0)
    im2 = np.expand_dims(np.flipud(resize(plt.imread(impath), [H,W])), 0)
    p1 = model.predict(im1)
    p2 = model.predict(im2)
    
    clss1 = np.argmax(p1[0])
    clss2 = np.argmax(p2[0])
    len1 = p1[1][0][0]
    len2 = p2[1][0][0]
    
    if( np.max(p1[0]) > np.max(p2[0]) ):
        clssf = clss1
        lenf = len1
    else:
        clssf = clss2
        lenf = len2
    
    if(clss1 == clss2):
        topred.iloc[i, classes_agree_col] = 1    
    if( np.abs(len1 - len2)/np.max([len1, len2]) <= 0.2 ): # if err < 20%
        topred.iloc[i, lengths_agree_col] = 1    
    
    topred.iloc[i, pred_cls_col] = clssf
    topred.iloc[i, pred_len_col] = lenf
    
print("100% Done")
topred["pred_cls_literal"] = [
f"between {vmin} to {vmax} mm"
for vmin, vmax in zip(
    [int(np.round(MODEL_BINS[v])) for v in topred["pred_cls"]],
    [int(np.round(MODEL_BINS[v+1])) for v in topred["pred_cls"]]
)]
topred.to_csv(OUTPUT_PREDICTIONS_PATH, index=False, mode='a', header=False)
print("Predictions Saved!")

print("Program Exsiting Succefully...")

"""
df2 = pd.concat([df_train, df_val, df_test], axis=0).rename(columns={"filename":"image_name"})
df3 = (
   topred.set_index("image_name")
   .join(
       df2.loc[:,["image_name","length"]]
       .set_index("image_name"), 
       how='inner'
       )
)

df3
""";
