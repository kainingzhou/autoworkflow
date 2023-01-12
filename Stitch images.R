#=============================================================
#===== Task ==================================================
#=============================================================
# 1. Stitch images in order to generate the soil profile
# 2. Add annotation of the soil depth on top of the stitched image

#===== Load libraries ========================================
library(magick)

# Set the current working directory
setwd("C:/Users/Kaining/Dropbox/daily")

# Access to another folder and work on files in it 
path <- ("C:/Users/Kaining/Dropbox/Apps/RootCamPy/cam1/L00")

#---Remove last black image-------
pics <- dir(path, full.names = TRUE)
unlink(pics[19]) 

# Stitch images and export result to the current directory
  pics[18:1] %>%
  image_read() %>%
  image_append(stack = TRUE) %>%
  image_write("Soil profile.jpg")
  
# Add annotation of soil depth

### WARN #######
################
# Because the 'magick' package cannot annotate on a list of images it couldn't annotate directly on the stitched image
# To overcome this issue, save the stitched image first, then call this image
  
s <- image_read("C:/Users/Kaining/Dropbox/daily/Soil profile.jpg") %>% 
     image_annotate("Soil depth: 0 cm", size = 200, gravity = "north", color = "black", boxcolor = "yellow") %>% 
     image_annotate("Soil depth: 30 cm", size = 200, gravity = "center", color = "black", boxcolor = "yellow") %>% 
     image_annotate("Soil depth: 60 cm", size = 200, gravity = "south", color = "black", boxcolor = "yellow") 
  
print(s)
  
g <- image_scale(s,"800x8000!")
  
print(g)
  
image_write(g, path = "Soil profile with annotation.jpg", format = "jpg")
  