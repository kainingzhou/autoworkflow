#=============================================================
#===== Task ==================================================
#=============================================================
# 1. Make the plot of RLD changes with DAP, in another word, time series RLD data
# 2. Make the plot of Maximum rooting depth change with DAP

#===== Set work directory ====================================
setwd("C:/Users/Kaining/Dropbox/daily")

#===== Load libraries ========================================
library(tidyr)# make wide data long
library(dplyr)
library(xlsx) # Write data into excel
library(readxl)
library(ggplot2)
library(export)
library(ggpubr)
library(RColorBrewer)# Use this to customize line colors

#===== Load data =============================================
est <- read.csv("Estimated RL for plot.csv") 
#est <- read.csv("TRL.csv") 

View(est)

str(est)

colnames(est)

#===== Data preparation =============================================================
# Adam's model is used for estimating root length of images taken by the manual MR camera.
# However, the size of each image taken by the automated MR camera is 25/18 = 1.388889 larger than those taken by the manual MR camera.
# Therefore, need to calculate the true root length by multiply the following factor
est$est_len<- est$pred_len*1.388889

# Create a column of the real window code by generating repeated sequences of specified numbers 
window_code <- rep(c(18:1), times=5) # Because in this demonstration, there are five dates in total
window_code

# Create a column of days after planting (DAP) by generating sequence with repeating numbers 
DAP <- rep(c(1:5), each=18)
DAP

# Arrange datasheet and keep the most important columns (1) DAP, (2) window_code, and (3) est_len
new_est <- transform(est, # The first three lines are to extract the information of 'date' and 'image_code' 
          image_code = substr(image_name, 4, 5), # Method: split the column of 'image_name' by number of characters 
          date = substr(image_name, 7, 14)) %>% # Tutorial: https://stackoverflow.com/questions/38252823/splitting-columns-by-number-of-characters
          subset(!(image_code %in% c(34))) %>% # Delete the images which do not contain roots. In this case, those images with image_code = 34
          cbind(window_code, DAP) %>% # insert columns of 'window_code' and 'DAP'
          subset(select = c(DAP, window_code, est_len)) # keep the most important columns

View(new_est)

# Calculate the real soil depth by image's window_code since the dimension of each image is 2.5cm width * 1.9cm height 
new_est_2 <- new_est %>% mutate(soil_depth =
                                        case_when(window_code <= 3 ~ "-10", 
                                                  window_code <= 6 ~ "-20",
                                                  window_code <= 9 ~ "-30",
                                                  window_code <= 12 ~ "-40",
                                                  window_code <= 15 ~ "-50",
                                                  window_code <= 18 ~ "-60"))     

View(new_est_2)

# Calculate TRL in each depth range
new_est_3<- new_est_2 %>%
  group_by(DAP, soil_depth) %>% 
  summarise_at(vars("est_len"), sum)

# assigning the third column name to a new name to clarify that each value in this column is the TRL at each 10 cm
colnames(new_est_3)[3] <- "est_TRL"

View(new_est_3)

# Calculate RLD in each soil depth interval. It is 10 cm in this case
new_est_4<- new_est_3 %>% 
  mutate(
    est_RLD = (est_TRL/10)/(10*2.5)
  ) # Calculate RLD with unit of cm/cm2

View (new_est_4)

# Redefine class of certain columns in order to plot gradient graph later
new_est_4$DAP <- as.numeric(new_est_4$DAP)
new_est_4$soil_depth <- as.numeric(new_est_4$soil_depth)

#===== Make plot of RLD change with DAP ===============================================================
ggplot(
  new_est_4,
  aes(
    soil_depth,
    est_RLD,
    colour = DAP,
    group = DAP
  )
)+
  geom_line(
    size= 1
  )+
  scale_colour_gradient2(
    name = "Days after \nplanting",
    low = "white",
    mid = "blue",
    high = "darkblue",
    midpoint = 3 # The midpoint of the DAP need to be changed according to the experiment
  )+
  scale_x_continuous(
    breaks = seq(-60,
                 -10,
                 by = 10
    )
  )+
  theme_classic()+
  theme(
    legend.title = element_text(
      size = 24
    ),
    legend.text = element_text(
      size = 20
    ),
    axis.text.x = element_text(
      size = 20, 
      color = "black",
      vjust = -0.5 # increase space between axis.text.x and axis.x
    ),
    axis.text.y = element_text(
      size=20, 
      color="black",
      hjust = 0.5  # increase space between axis.text.y and axis.y
    ),
    axis.title.x = element_text(
      size = 24,
      margin = margin(
        t = 20, 
        r = 0, 
        b = 0, 
        l = 0),
    ),
    axis.title.y = element_text(
      size = 24,
      margin = margin(
        t = 0, 
        r = 20, 
        b = 0, 
        l = 0)
    ),
    axis.line = element_line(
      size = 1, 
      colour = "black"
    ),
    axis.ticks.length = unit(0.2, "cm"),
    axis.ticks = element_line(
      size = 1
    ),
    legend.position = "right",
    legend.spacing.y = unit(0.7, 'cm'),
    legend.key.size = unit(1, 'cm')
  )+
  labs(
    x = "Soil depth (cm)",
    y = expression("Root length density (cm/cm"^2*")")
  ) +
  coord_flip()+
  ylim(0, 0.8)

graph2png(file="RLD change with DAP.png")

#=== Rooting depth ===========

#Rdep <- new_est_2 [new_est_2$est_len > 6,] # First exclude windows do not contain roots, the threshold is set as TRL = 6 mm per image 

#Rdep<- Rdep %>%
  #group_by(DAP) %>%  
  #summarise_at(vars("window_code"), max) %>%  
  #mutate(Max_rooting_depth = window_code * 1.9)# Then choose the the deepest depth as the maximum rooting depth

# Make graph
#ggplot(
  #Rdep,
  #aes(
    #DAP,
   # Max_rooting_depth
  #)
#)+
  #geom_line(
   # size= 1.5,
   # color="darkred"
  #)+
  #scale_x_continuous(
  #  breaks = seq(0,
                 #5,
                 #by = 1
   # )
  #)+
  #theme_classic()+
  #theme(
    #plot.title = element_text(
      #size = 28,
      #face = "bold", 
      #colour = "black", 
      #hjust = 0.5
    #),
    #axis.title = element_text(
      #size=24
    #),
    #axis.text.x = element_text(
      #size=24, 
      #color="black",
      #vjust = -0.5 #increase space between axis.text and axis
    #),
    #axis.text.y = element_text(
      #size=24, 
      #color="black",
      #hjust = 0.5
    #),
    #axis.title.x = element_text(
      #margin = margin(
        #t = 20, 
        #r = 0, 
        #b = 0, 
        #l = 0)
    #),
    #axis.title.y = element_text(
      #margin = margin(
        #t = 0, 
        #r = 20, 
        #b = 0, 
        #l = 0)
    #),
    #axis.line = element_line(
      #size = 1, 
      #colour = "black"
    #),
    #axis.ticks.length = unit(0.2, "cm"),
    #axis.ticks = element_line(
      #size = 1
    #)
  #)+
  #labs(
    #x = "Days after planting",
    #y="Maximum rooting depth (cm)"
  #)

# Export graph
#graph2ppt(file="ggplot2_plot.pptx", width=6, height=8, append = TRUE)










