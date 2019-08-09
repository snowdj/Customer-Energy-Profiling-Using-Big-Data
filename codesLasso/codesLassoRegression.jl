using CSV, StatsBase, GLM, CSV, Distributions, RCall, CategoricalArrays
myTrain = CSV.read("myTrainNC.csv");
myValid = CSV.read("myValid.csv");
myTest = CSV.read("myTestNC.csv");


@rput myTrain  # to tansfer from Julia --> R
@rput myValid
@rput myTest
R"""
# install.packages("gglasso")
# install.packages("dplyr")
library(gglasso)
library("dplyr")

factorCols = c("WALLTYPE","ROOFTYPE","PRKGPLC1","STOVENFUEL","DEFROST","TOASTER","FUELFOOD","COFFEE","TYPERFR1","TREESHAD","TVTYPE1","INTERNET"
               ,"WELLPUMP","AQUARIUM","STEREO","MOISTURE","FUELH2O","PROTHERMAC","RECBATH","SLDDRS","USENG","USESOLAR","ELWARM","ELWATER"
               ,"ELFOOD","EMPLOYHH","Householder_Race","EDUCATION","RETIREPY","POVERTY150")
myTrain[factorCols] = lapply(myTrain[factorCols], factor)
myValid[factorCols] = lapply(myValid[factorCols], factor)
myTest[factorCols]  = lapply(myTest[factorCols], factor)

len = length(myTrain)

levels = rep(0,69)
for (i in 1:len)
{
  if(is.factor(myTrain[,i]) ==FALSE)
  {levels[i]=1}
  else
  {
    levels[i] = length(levels(myTrain[,i]))-1
  }
}
groups = rep(levels[1],levels[1])
for(i in 1:len)
{
  groups = c(groups, rep(i,levels[i]))
}
groups = groups[2:101]; # need to eliminate the first one and last one --> THINK..!

xTrain = model.matrix( ~ ., dplyr::select(myTrain, -KWH))[, -1];
xValid  = model.matrix( ~ ., dplyr::select(myValid, -KWH))[, -1];
yTrain = myTrain$KWH; yValid = subset(myValid, select=c(KWH))
obs = dim(yValid)[1]

lambdas = c(0,1,1.5,6.5,6.7,8,11,13,16,18,19,23,24,25,27,32,33,34,41,56,60,65,75,78,80,85,100,108,110,115,121,125,130,155,160,170,180,187.5,
            189,195,250,350,400,500,600,688,700,800,850,950,1000,1100,1200,1250,1300,1700,2450,2800,3000,3400,4500,5500,18000,35000,800000,
            2000000,5000000,100000000)
lambdas = c(1000,1500,2000)                         ## TO CHANGE--> Just delete this line. trust me, rest will be good.!
obs = length(lambdas)
fits <- list()
coef <- list()
predict <- list()

for(i in 1:obs){
  fits[[i]] = gglasso(x = xTrain, y = yTrain, group = groups, lambda = lambdas[i],loss="ls")
  coef[[i]] = fits[[i]]$beta
  predict[[i]] = predict(fits[[i]],type = "class",newx=xValid)
}

rSquaredVal = rep(0,68)
rSquaredVal = rep(0,3)                              ## TO CHANGE--> Just delete this line. trust me, rest will be good.!
for(i in 1:obs)
{
  rSquaredVal[i] =  1-((sum((yValid-predict[[i]])^2))/ (sum((yValid- mean(data.matrix(predict[[i]])))^2)))
}
#plot(rSquaredVal)

stdErr = rep(0,68)
stdErr = rep(0,3)                                   ## TO CHANGE --> Just delete this line. trust me, rest will be good.!
for(i in 1:obs)
{
  stdErr[i] = sqrt(mean(data.matrix((yValid-predict[[i]])^2)))
}
#plot(stdErr)
"""