# Clearing environment

rm(list = ls())

# Loading Libraries

pacman::p_load(ggplot2, tidyverse, dplyr, rio, forecast, zoo)

# Importing data set

marriott <- import("simplified_marriot.xlsx") %>% as_tibble()




# Creating new variable "norm_ratio" that has normalized pickup ratio

marriott$norm_ratio <- marriott$pickup_ratio/marriott$dow_index

# Creating a new data frame removing rows with missing values which we need to forecast

marriott2 <- marriott[1:87,]

# Creating a time series for norm_ratio

start_date <- as.Date("1987-05-23")

end_date <- as.Date("1987-08-17")

date_seq <- seq(start_date, end_date, by="days")

mts <- ts(marriott2)

# Plotting time series for the data

autoplot(mts[,"norm_ratio"])

# Splitting data into training and validation (80-20)

mts_train <- window(mts, end = time(mts)[69])
mts_valid <- window(mts, start=time(mts)[70])

# Creating a tslm model

tslm_mts <- tslm(norm_ratio ~ trend, data = mts_train)

# Predicting values for the next

tslm_predict <- forecast(tslm_mts, h = 18)

# plotting tslm fitted values

plot(tslm_mts$fitted.values, ylim=c(0.5,1.5))
lines(mts[,"norm_ratio"])
lines(tslm_predict$mean)

# Getting accuracy values

accuracy(tslm_predict, mts[,"norm_ratio"])

# Splitting data into training and validation (70-30)

mts_train2 <- window(mts, end = time(mts)[60])
mts_valid2 <- window(mts, start=time(mts)[61])

# Creating naive model

naive_predict <- rep(x = mts_train[length(mts_train2[,"norm_ratio"]),"norm_ratio"],times = length(mts_valid2[,"norm_ratio"]), by =0)

# Getting accuracy

accuracy(naive_predict, mts_valid2[,"norm_ratio"])

# Plotting

naive_df <- cbind(mts_valid2[,"norm_ratio"], naive_forecast = naive_predict)
plot(mts[,"norm_ratio"], ylim=c(0.5,1.5))
lines(naive_df[,"naive_forecast"], lty=2, lwd=2, col='pink')
legend("bottomright", legend = ("Naive Model"),col = ("pink"),lty = 1, lwd = 1)


# Creating a moving average model

ma_mts <- ma(mts_train2[,"norm_ratio"], order = 3, centre = T)

# Generating forecast

ma_predict <- forecast(ma_mts, h = length(mts_valid2[,"norm_ratio"]))

# Getting accuracy

accuracy(ma_predict, mts[,"norm_ratio"])

# Plotting

plot(mts[,"norm_ratio"], ylim=c(0.5,1.5))
lines(ma_predict$mean, lwd = 2, lty = 2, col='pink')
lines(ma_mts, lwd = 2, lty = 2, col='magenta')
legend("bottomright", legend = c("Fitted Values","Forecast-Moving Average"),
       col = c("magenta","pink"),lty = c(1,2), lwd = c(1,2))


# Creating a tslm linear trend model

tslm_mts2 <- tslm(norm_ratio ~ trend, data = mts_train2)

summary(tslm_mts2)

# Predicting values for the next

tslm_predict2 <- forecast(tslm_mts2, h = 52)

# calculating accuracy

accuracy(tslm_predict2, mts[,"norm_ratio"])

# plotting tslm fitted values

plot(mts[,"norm_ratio"], ylim=c(0.5,1.5))
lines(tslm_mts2$fitted.values, lty=2, lwd=2, col='magenta')
lines(tslm_predict2$mean, col = "pink", lty=2, lwd=2)
legend("bottomright", legend = c("Fitted Values","Forecast-TSLM Linear"),
       col = c("magenta","pink"),lty = c(1,2), lwd = c(1,2))





# Creating a tslm polynomial trend model

ptslm_mts <- tslm(norm_ratio ~ trend + I(trend^2) , data = mts_train2)

summary(ptslm_mts)

# Predicting values for the next

ptslm_predict <- forecast(ptslm_mts, h = length(mts_valid2[,"norm_ratio"]))

# plotting tslm quadratic model

plot(mts[,"norm_ratio"], ylim=c(0.5,1.5))
lines(ptslm_mts$fitted.values, lty=2, lwd=2, col='magenta')
lines(ptslm_predict$mean, col = "pink", lty=2, lwd=2)
legend("bottomright", legend = c("Fitted Values","Forecast-TSLM Quadratic"),
       col = c("magenta","pink"),lty = c(1,2), lwd = c(1,2))

# Getting accuracy values

accuracy(ptslm_predict, mts[,"norm_ratio"])

# Creating Arima model

arima_mts <- auto.arima(mts_train2[,"norm_ratio"])

# Generating predictions

arima_predict <- forecast(arima_mts, h=length(mts_valid2[,"norm_ratio"]))

# Getting accuracy values

accuracy(arima_predict, mts[,"norm_ratio"])

# plotting

plot(mts[,"norm_ratio"], ylim=c(0.5,1.5))
lines(arima_mts$fitted, lty=2, lwd=2, col='magenta')
lines(arima_predict$mean, col = "pink", lty=2, lwd=2)
legend("bottomright", legend = c("Fitted Values","Forecast-ARIMA"),
       col = c("magenta","pink"),lty = c(1,2), lwd = c(1,2))

# Creating ets "AAN"

ets_mts <- ets(mts_train2[,"norm_ratio"], model = "AAN")

# Generating forecast

ets_predict <- forecast(ets_mts, h = length(mts_valid2[,"norm_ratio"]))

# Calculating accuracy

accuracy(ets_predict, mts[,"norm_ratio"])

# Plotting fitted, actual and forecast values


plot(mts[,"norm_ratio"], ylim=c(0.5,1.5))
lines(ets_predict$mean, lty = 2, lwd = 3, col='pink')
lines(ets_mts$fitted, lty = 2, lwd = 3, col = 'magenta')
legend("bottomright", legend = c("Fitted Values","Forecast-ETS(AAN)"),
       col = c("magenta","pink"),lty = c(1,2), lwd = c(1,2))

# Combined forecast plots of all models

plot(mts[,"norm_ratio"], ylim=c(0.5,1.5), lwd = 2)
lines(naive_df[,"naive_forecast"], lty=2, lwd=2, col='pink')
lines(ma_predict$mean, lwd = 2, lty = 2, col='blue')
lines(tslm_predict2$mean, col = "red", lty=2, lwd=2)
lines(ptslm_predict$mean, col = "brown", lty=2, lwd=2)
lines(ets_predict$mean, lty = 2, lwd = 3, col='green')
lines(arima_predict$mean, col = "orange", lty=2, lwd=2)

legend("bottomright", legend = c("Naive","Moving Average","TSLM-Linear", "TSLM-Quadratic","ETS(AAN)","ARIMA"),
       col = c("pink","blue","red","brown","green","orange"),
       lty = c(2,2,2,2,2,2), lwd = c(2,2,2,2,2,2))


#### Differened data ####

#### undiff function ####

mts_diff = diff(mts, lag = 1)
mts_diff_train <- window(mts_diff, end = time(mts)[60])
mts_diff_valid <- window(mts_diff, start=time(mts)[61])

autoplot(mts_diff[,"norm_ratio"])

# tslm with linear trend

tslm_mts_diff <- tslm(norm_ratio ~ trend , data = mts_diff_train)

summary(tslm_mts_diff)

# predicting differenced data

tslm_diff_predicted <- forecast(tslm_mts_diff, h = length(mts_diff_valid[,"norm_ratio"]))

tslm_pred_undiff<- diffinv(tslm_diff_predicted$mean, xi = mts_train2[60,"norm_ratio"])[-1]

accuracy(tslm_pred_undiff, mts_valid2[,"norm_ratio"])


arima_mts_diff <- auto.arima(mts_diff_train[,"norm_ratio"])
arima_diff_predicted <- forecast(arima_mts_diff, h = length(mts_diff_valid[,"norm_ratio"]))
arima_pred_undiff<- diffinv(arima_diff_predicted$mean, xi = mts_train2[60,"norm_ratio"])[-1]
accuracy(arima_pred_undiff, mts_valid2[,"norm_ratio"])

ets_mts_diff <- ets(mts_diff_train[,"norm_ratio"],model='AAN')
ets_diff_predicted <- forecast(ets_mts_diff, h = length(mts_diff_valid[,"norm_ratio"]))
ets_pred_undiff<- diffinv(ets_diff_predicted$mean, xi = mts_train2[60,"norm_ratio"])[-1]
accuracy(ets_pred_undiff, mts_valid2[,"norm_ratio"])


# Plots

mts_diff_df <- cbind(mts_valid2[,"norm_ratio"],tslm_pred_undiff=tslm_pred_undiff,
                     arima_pred_undiff=arima_pred_undiff,ets_pred_undiff=ets_pred_undiff)



plot(mts[,"norm_ratio"], ylim=c(0.5,1.5), lwd = 2)
lines(mts_diff_df[,"tslm_pred_undiff"], lwd = 2, lty = 2, col='blue')
lines(mts_diff_df[,"arima_pred_undiff"], lty=2, lwd=2, col='pink')
lines(mts_diff_df[,"ets_pred_undiff"], lty=2, lwd=2, col='red')
legend("bottomright", legend = c("TSLM", "ARIMA", "ETS"),
       col = c("blue", "pink", "red"), lty = c(2, 2, 2), lwd = c(2, 2, 2))


# Finalizing ets model with differenced input data

ets_final <- ets(mts_diff[,"norm_ratio"], model = 'AAN')

# Generating forcast for next 11 days

ets_final_forecast_diff <- forecast(ets_final, h = 11)

# Inverse differencing the predictions

ets_final_forecast <- diffinv(ets_final_forecast_diff$mean, xi = mts[87,"norm_ratio"])[-1]


plot(ets_final_forecast, ylim=c(0.5,1.5), lwd = 2, lty=2)

# feeding this final forecasted value in our main df

marriott[88:98,"norm_ratio"] <- ets_final_forecast

marriott[88:98,"dow_index"] <- marriott[4:14,"dow_index"]

marriott[88:98,"pickup_ratio"] <- marriott[88:98,"norm_ratio"]*marriott[88:98,"dow_index"]

marriott[88:98,"demand"] <- marriott[88:98,"pickup_ratio"]*marriott[88:98,"Tuesday_bookings"]

export(marriott,"marriott_final.csv",format='csv')

