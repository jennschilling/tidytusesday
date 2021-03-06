# Author : Jenn Schilling
# Title: #TidyTuesday Washington Hiking
# Date: 11/24/2020

#### Libraries ####

library(tidytuesdayR)
library(tidyverse)
library(skimr)
library(showtext)
library(sysfonts)

# Add font
font_add_google("Roboto")

showtext_auto()

#### Get the Data ####

tuesdata <- tidytuesdayR::tt_load('2020-11-24')

hike_data <- tuesdata$hike_data %>% 
  unique(.)

#### Explore the Data ####

skim(hike_data)



#### Data manipulation ####

# Make columns numeric 
# Separate out length from the descriptors (miles, rountrip/one-way)
hike_data_num <- hike_data %>%
  mutate(gain = as.numeric(gain),
         highpoint = as.numeric(highpoint),
         rating = as.numeric(rating)) %>%
  separate(length, into = c("length", "length_type"), sep = ",") %>%
  separate(length, into = c("length", "length_dist_type"), sep = "\\s") %>%
  mutate(length = as.numeric(length))

# Alternate way to get numeric - use parse_number
# But then I miss out on the length_type of roundtrip vs one-way
hike_data_/num <- hike_data %>%
  mutate(gain = parse_number(gain),
         highpoint = parse_number(highpoint),
         rating = parse_number(rating),
         length = parse_number(length))

skim(hike_data_num)

table(hike_data_num$location)


# Separate out location
hike_data_num <- hike_data_num %>%
  mutate(location2 = location) %>%
  separate(location2, into = c("area", "region"), sep = " --")

table(hike_data_num$area)

# Puget Sound and Islands is the Seattle-Tacoma Area


# What about features?
hike_data_num_unnest <- hike_data_num %>%
  unnest(features)

hike_data_num_unnest %>%
  group_by(features) %>%
  summarise(mean_rating = mean(rating),
            mean_length = mean(length),
            mean_gain = mean(gain),
            n = n()) %>%
  arrange(-mean_rating)


#### Exploration Plotting ####

hike_data_num %>%
  filter(length < 50) %>%
  ggplot() +
  geom_point(aes(x = length, y = rating)) +
  facet_wrap(~area)

hike_data_num %>%
  filter(gain < 10000) %>%
  ggplot() +
  geom_point(aes(x = gain, y = rating)) +
  facet_wrap(~area)

# Doesn't seem to be a relationship between rating and length/gain


# Look at features and ratings 

hike_data_num_unnest %>%
  ggplot() +
  geom_boxplot(aes(x = rating, 
                   y = features))

hike_data_num_unnest %>%
  group_by(features) %>%
  summarise(mean_rating = mean(rating)) %>%
  ggplot() +
  geom_point(aes(x = mean_rating,
                 y = reorder(features, mean_rating)))


hike_data_num_unnest %>%
  group_by(features) %>%
  summarise(mean_rating = mean(rating),
            mean_length = mean(length),
            mean_gain = mean(gain)) %>%
  ggplot() +
  geom_point(aes(x = mean_gain,
                 y = reorder(features, mean_rating)))

# Characteristics of high rated hikes vs. low rated hikes??

hike_data_num %>%
  mutate(rating_level = ifelse(rating == 0, 0,
                         ifelse(rating < 2, 1,
                         ifelse(rating < 3, 2,
                         ifelse(rating < 4, 3,
                         ifelse(rating < 5, 4, 5)))))) %>%
  group_by(rating_level) %>%
  summarise(mean_length = mean(length),
            mean_gain = mean(gain),
            n = n()) %>%
  pivot_longer(mean_length:n) %>%
  ggplot() +
  geom_bar(aes(x = as.factor(rating_level), y = value, group = name),
           stat = "identity") +
  facet_wrap(~name,
             scales = "free")


#### Final Plot ####

hike_data_num_unnest %>%
  group_by(features) %>%
  summarise(mean_rating = mean(rating)) %>%
  ggplot(aes(x = mean_rating,
             y = reorder(features, mean_rating))) +
  geom_segment(aes(xend = 0,
                   yend = reorder(features, mean_rating)),
               size = 0.5) +
  geom_point(size = 3,
             color = "#228B22") +
  labs(x = "Average Rating",
       y = "Hike Features",
       title = "Hikes in Washington that do not allow dogs, feature waterfalls, or have established campsites are rated highest, on average.",
       caption = "TidyTuesday 24 Nov 2020 | Data: Washington Trails Association | Designer: Jenn Schilling | jennschilling.me") +
  scale_x_continuous(limits = c(0, 5),
                     expand = expansion(mult = c(0, .1))) +
  theme_classic() +
  theme(text = element_text(family = "Roboto"),
        plot.title.position = "plot",
        axis.ticks.y = element_blank())

