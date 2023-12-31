################
# Code for creating Figure 7.6 & Table 7.1 (WalMart Sales - use of automated ARIMA)

one.pair <- read.csv("Data/Walmart_One_Pair.csv")

one.pair <- one.pair |>
  mutate(Week = yearweek(one.pair$Date)) |>
  filter(!is.na(Weekly_Sales)) |> # removes rows where Weekly_Sales is NA
  as_tsibble(index = Week)

one.pair.train <- one.pair |> filter_index(~ "2012 W05")     # 2 years (105 weeks)
one.pair.valid  <- one.pair |> filter_index("2012 W06" ~ "2012 W43")  # 38 weeks

# Automated ARIMA on training
fit.aut.arima <- one.pair.train |>
  model(model.stepwise = ARIMA(Weekly_Sales),   # using the default stepwise procedure
        model.search   = ARIMA(Weekly_Sales, stepwise = FALSE)) # search a larger model space

######## Table 7.1
fit.aut.arima # selected models

# Alternatives:
fit.aut.arima |> select(model.stepwise) |> report()
fit.aut.arima |> select(model.search) |> report()

glance(fit.aut.arima) 

####### Figure 7.6
# Forcasting
fc <- fit.aut.arima |>
  forecast(one.pair.valid)

# Performance measures
accuracy(fit.aut.arima) # training
accuracy(fc, one.pair.valid) # validation

# Compute validation forecast errors
# add them to new fc2
fc2 <- fc |>
  left_join(one.pair.valid, by = "Week") |>
  mutate(fc.error = one.pair.valid$Weekly_Sales - fc$.mean)

# Plot 1: actual and forecasts
p1 <- autoplot(one.pair, Weekly_Sales) +
  autolayer(fitted(fit.aut.arima), .fitted, alpha = 0.7) +
  autolayer(fc, .mean, linetype = "dashed", level = NULL) +
  labs(title = "Sales and Forecasts", x = "Week", y = "Sales")

# Plot 2: errors
p2 <- autoplot(fc2, fc.error, linetype = "dashed") +
  autolayer(resid(fit.aut.arima), .resid, alpha = 0.7) +
  labs(title = "Errors", x = "Week", y = "Error")

grid.arrange(p1, p2 , nrow = 2)
