# Install from CRAN
install.packages("tidyverse")

# Open Working Directory
setwd("Desktop")
getwd()

path_to_my_datafiles <- "Desktop/hottest_year_visual/"
list.files(path = path_to_my_datafiles, 
        pattern = NULL,
     full.names = TRUE)


library(tidyverse) 

# Format merra2_seas_anom.txt
month_anom<- read_table(file = "data/merra2_seas_anom.txt", skip = 3) %>%
  select(month = Month, seas_anom) %>%
  mutate(month = as.numeric(month), 
         month = month.abb[month])

#Format GLB.Ts+dSST.csv
t_data <- read_csv("data/GLB.Ts+dSST.csv", skip = 1, na = "*******") %>%
  select(year = Year, all_of(month.abb)) %>%
  pivot_longer(-year, names_to="month", values_to="t_diff") %>%
  drop_na() %>%
  inner_join(., month_anom, by="month") %>%
  mutate(month = factor(month, levels = month.abb)) %>%
  mutate(t_diff = as.numeric(t_diff), seas_anom = as.numeric(seas_anom), month_anom = t_diff + seas_anom - 0.7) %>%
  group_by(year) %>%
  mutate(ave= mean(month_anom)) %>%
  ungroup() %>%
  mutate(ave = if_else(year == 2022, max(abs(ave)), ave))

annotation <- t_data %>%
  slice_tail(n = 1)

p <- t_data %>%
  ggplot(aes(x=month, y=month_anom, group=year, color=ave)) +
  geom_line() + 
  geom_point(data = annotation, aes(x=month, y=month_anom)) +
  scale_color_gradient2(low = "darkblue", mid = "white", high = "darkred",
                        midpoint = 0, guide = "none") +
  scale_y_continuous(breaks = seq(-3, 2, 1)) +
  scale_x_discrete(expand= c(0,0)) +
  labs(x = NULL,
       y = NULL, 
       title = "Temperature Anomaly (\u00B0 C)",
       subtitle = "(Difference from 1980-2015 annual mean)") +
  theme(
    panel.background = element_blank(),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.grid.major.y = element_line(color="gray", linetype = "dotted", size = 0.25),
    plot.title.position = "plot",
    plot.title = element_text(face = "bold"),
    plot.subtitle = element_text(color = "gray", size = 10),
    plot.margin = margin(t = 20, r = 25, b = 20, l = 25)
    )

p +
  geom_point(data = annotation, aes(x=month, y=month_anom), size = 5) +
  geom_text(data=annotation, aes(x=3.5, y=-1.95),
            label="March 2022", hjust=1)

ggsave(visuals/monthly_anomaly.png", width=6, height=4, units="in")