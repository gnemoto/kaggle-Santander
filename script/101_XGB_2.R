library(data.table)
library(ggplot2)
library(xgboost)
library(Matrix)

# load data
suppressWarnings(data <- fread("/home/rstudio/Santander/indat/train_ver2.csv"))
#suppressWarnings(data <- fread("../indat/train_ver2.csv"))
data[, submission := FALSE]
suppressWarnings(data_test <- fread('/home/rstudio/Santander/indat/test_ver2.csv'))
#suppressWarnings(data_test <- fread('../indat/test_ver2.csv'))
data_test[, submission := TRUE]
data <- rbind(data, data_test, fill = TRUE)
data[, ':='(fecha_dato = as.Date(fecha_dato), fecha_alta = as.Date(fecha_alta))]
setorder(data, ncodpers, fecha_dato)

# select product columns
prod_cols <- colnames(data)[grep('^ind.*ult1$', colnames(data))]

data[submission == FALSE, n_purch := 0]

# for each product calulate if it was bought in the given month
for (col in prod_cols) { #not very efficient ...
  cat(col)
  purch_var <- paste('purch', col, sep = '_')
  ok = FALSE
  while(!ok) { #ugly, but data.table throws me an error randomly 
    cat('.')
    try({
      data[, (purch_var) := (get(col) * (!c(NA, get(col)[-.N]))), by = ncodpers]
      data[fecha_alta == fecha_dato, (purch_var) := get(col)]
      data[, (paste0('has_', col)) := c(NA, get(col)[-.N]), by = ncodpers]
      data[get(purch_var) == 1, n_purch := n_purch + 1]
      ok = TRUE
    }, silent = TRUE)
  }
  cat('done/n')
}

positive_m_frac <- data[,mean(n_purch > 0, na.rm = TRUE)] # fraction of customers who buy anything new

# plot some stuff
# suppressWarnings(
# print(data[n_purch > 0,list(count = .N),by = n_purch])
# ggplot(data[n_purch > 0, .(n_purch)], aes(x = n_purch)) + geom_bar()
# ) 

# remove product cols (no more needed) and data where nothing new was bought
melt_data <- data[(n_purch > 0) | (submission == TRUE), -prod_cols, with = FALSE]

# free some memory
data <- NULL
gc();gc()

# variable definitions
purch_cols <- paste0('purch_', prod_cols) 
has_cols <- paste0('has_', prod_cols)
id_vars <- c('fecha_dato', 'ncodpers', 'submission', 'n_purch')
num_vars <- c('age', 'antiguedad', 'renta', has_cols)
exclude_vars <- c('fecha_alta', 'ult_fec_cli_1t', prod_cols)
cat_vars <- setdiff(colnames(melt_data), c(id_vars, num_vars, exclude_vars, purch_cols))

# melt variables correspondning to new products
melt_label <- melt(melt_data, 
                   id.vars = id_vars, 
                   measure.vars = purch_cols,
                   variable.name = 'purch')

# choose ony th rows where something was bought
melt_label <- melt_label[value == 1,-'value',with = FALSE]

# plot some stuff
# print(melt_label[,list(n_purch = .N),by = purch])
# ggplot(melt_label, aes(x = fecha_dato, fill = purch)) + geom_bar()

#melt numerical and categorical variables separately
melt_num <- suppressWarnings(
  melt(melt_data, id.vars = c(id_vars), measure.vars = c(num_vars)))
melt_cat <- suppressWarnings(
  melt(melt_data, id.vars = c(id_vars), measure.vars = c(cat_vars)))

# assign column numbers for data
num_columns <- unique(melt_num[,.(variable)])
num_columns[, column := 1:.N]
cat_columns <- unique(melt_cat[,.(variable, value)])
cat_columns[, column := (1:.N) + nrow(num_columns)]

melt_num <- num_columns[melt_num,,on = 'variable']
melt_cat <- cat_columns[melt_cat,,on = c('variable', 'value')]

# checkup
cat('Test data:', 
    nrow(unique(melt_num[submission == TRUE, .(fecha_dato, ncodpers)])), 
    ' vs ', 
    nrow(data_test), '/n')

# more data preparation and label encoding
get_data <- function(rows, label_coding = NULL) {
  rows[, row := 1:.N]
  rows <<- rows
  num_data <- melt_num[rows[,c(id_vars, 'row'),with = FALSE],, on = id_vars]
  cat_data <- melt_cat[rows[,c(id_vars, 'row'),with = FALSE],, on = id_vars]
  
  if(is.null(label_coding)) {
    label_coding <- unique(rows[,.(purch)])
    label_coding[, label := (1:.N) - 1]
  }
  if ('purch' %in% colnames(rows))
    rows <- label_coding[rows,,on='purch']
  else
    rows[,label := NA]
  
  data <- sparseMatrix(i = c(num_data[,row], cat_data[,row]),
                       j = c(num_data[,column], cat_data[,column]),
                       x = c(num_data[,value], rep(1, nrow(cat_data))),
                       dims = c(nrow(rows), cat_columns[,max(column)])
  )
  colnames(data) <- c(num_columns[,levels(variable)], cat_columns[,paste(variable, value, sep = "_")])
  
  return(list(data = data, label = rows[,label], rows = rows, label_coding = label_coding))
}

# split data
set.seed(123)
train_obs <- which(runif(nrow(melt_label)) < 0.8)
test_obs <- setdiff(1:nrow(melt_label), train_obs)

train_list <- get_data(melt_label[train_obs])
test_list <- get_data(melt_label[test_obs], train_list$label_coding)

train <- xgb.DMatrix(data = train_list$data, label = train_list$label)
test <- xgb.DMatrix(data = test_list$data, label = test_list$label)

n_class <- nrow(train_list$label_coding)

# train model
set.seed(1234)
model <- xgb.train(data = train,
                   watchlist = list(test = test, train = train),
                   params = list(
                     objective = 'multi:softprob',
                     eta = 0.1,  #original 0.05
                     max_depth = 12, #original 8
                     subsample = 0.8,
                     num_class = n_class
                   ),
                   nrounds = 113,
                   print.every.n = 1,
                   maximize = FALSE
)

# make recommendation order
recommend <- function(data, rows) {
  pred <- predict(model, data)
  pred <- matrix(pred, ncol = n_class, byrow = TRUE)
  recom <- t(apply(pred, 1, order, decreasing = TRUE)) - 1
  recom <- cbind(rows[,.(fecha_dato, ncodpers)], data.table(recom))
  # if there are multiple rows for one customer - take first one (all are the same)
  recom <- recom[, lapply(.SD, '[', 1), by = list(fecha_dato, ncodpers)] 
  
  return(recom)
}

recommend2 <- function(data, rows, criterion=0.1, cumsum=FALSE) {
  pred <- predict(model, data)
  pred <- matrix(pred, ncol = n_class, byrow = TRUE)
  pred.sorted = t(apply(pred, 1, sort, decreasing = TRUE))
  recom <- t(apply(pred, 1, order, decreasing = TRUE)) - 1
  # remain prods these probabilities are over criterion 
  if(!cumsum){
    recom <- ifelse(pred.sorted>criterion, recom, NA)
  }else{
    pred.cumsum <- t(apply(pred.sorted, 1, cumsum))
    recom <- ifelse(pred.cumsum<criterion, recom, NA)
  }
  recom <- cbind(rows[,.(fecha_dato, ncodpers)], data.table(recom))
  # if there are multiple rows for one customer - take first one (all are the same)
  recom <- recom[, lapply(.SD, '[', 1), by = list(fecha_dato, ncodpers)] 
  
  return(recom)
}

#recom <- recommend(test, test_list$rows)
recom <- recommend2(test, test_list$rows, 0.01, FALSE)
head(recom)

# calculate MAP@7
MAP <- function(recom, data_list, at = 7) {
  real <- data_list$rows
  joy <- real[recom,,on = c('fecha_dato', 'ncodpers')]
  rec_cols <- setdiff(colnames(recom), c('fecha_dato', 'ncodpers'))[1:at]
  labels <- joy$label
  hits <- joy[, lapply(.SD, '==', labels), .SDcols = rec_cols]
  ## convert NA to FALSE
  hits <- t(apply(hits, 1, function(x){ifelse(is.na(x), FALSE, x)}))
  hits <- cbind(joy[,.(fecha_dato, ncodpers)], hits)
  hits <- hits[,lapply(lapply(.SD, sum), '/', .N),by = list(fecha_dato, ncodpers)]
  mat <- as.matrix(hits[,.SD,.SDcols = rec_cols])
  mat <- t(apply(mat,1, cumsum)) * (mat > 0)
  mat <- mat / matrix(1:at, ncol = at, nrow = nrow(mat), byrow = TRUE)
  return(sum(mat)/nrow(mat))
}

cat('MAP@7:', MAP(recom, test_list) * positive_m_frac, "\n")
# MAP@7: 0.02360537 when maxdepth = 4
# MAP@7: 0.02397667 when maxdepth = 6
# MAP@7: 0.02408279 when maxdepth = 8
# MAP@7: 0.0241484  when maxdepth = 10
# MAP@7: 0.02419139 when maxdepth = 12 ��best
# MAP@7: NA         when maxdepth = 13
# MAP@7: NA         when maxdepth = 14

# MAP@7: 0.02423365

## output submission file
# check data
melt_data[submission  == TRUE, ]
melt_label[submission == TRUE, ]  ## 0 obs
melt_num[submission   == TRUE, ]

# prepair data for submission
submit_obs <- which(melt_data$submission == TRUE)

submit_list <- get_data(melt_data[submit_obs], train_list$label_coding)

submit <- xgb.DMatrix(data = submit_list$data, label = submit_list$label)

#recom_submit <- recommend(submit, submit_list$rows)
recom_submit <- recommend2(submit, submit_list$rows, 0.2)
head(recom_submit)

# ##function 'recommend'
# #recommend <- function(data, rows) {
#   pred <- predict(model, submit)
#   pred <- matrix(pred, ncol = n_class, byrow = TRUE)
#   recom <- t(apply(pred, 1, order, decreasing = TRUE)) - 1
#   recom <- cbind(rows[,.(fecha_dato, ncodpers)], data.table(recom))
#   # if there are multiple rows for one customer - take first one (all are the same)
#   recom <- recom[, lapply(.SD, '[', 1), by = list(fecha_dato, ncodpers)] 
#   return(recom)
# #}

# ## function 'MAP'
# # calculate MAP@7
# #MAP <- function(recom, data_list, at = 7) {
# at = 7
#   real <- submit_list$rows
#   joy <- real[recom,,on = c('fecha_dato', 'ncodpers')]
#   rec_cols <- setdiff(colnames(recom), c('fecha_dato', 'ncodpers'))[1:at]
#   labels <- joy$label
#   hits <- joy[, lapply(.SD, '==', labels), .SDcols = rec_cols]
#   hits <- cbind(joy[,.(fecha_dato, ncodpers)], hits)
#   hits <- hits[,lapply(lapply(.SD, sum), '/', .N),by = list(fecha_dato, ncodpers)]
#   mat <- as.matrix(hits[,.SD,.SDcols = rec_cols])
#   mat <- t(apply(mat,1, cumsum)) * (mat > 0)
#   mat <- mat / matrix(1:at, ncol = at, nrow = nrow(mat), byrow = TRUE)
#   sum(mat)/nrow(mat)
# #  return(sum(mat)/nrow(mat))
# #}

## convert labels to product names
recom_prod <- recom_submit[, c('fecha_dato', 'ncodpers')]
#for (i in 1){#n_class){
#  recom_prod <- cbind(recom_prod, as.data.table(prod_cols[as.matrix(recom_submit[, (i+1)])+1]))
recom_prod <- cbind(recom_prod, as.data.table(prod_cols[as.matrix(recom_submit[,  3])+1]))
recom_prod <- cbind(recom_prod, as.data.table(prod_cols[as.matrix(recom_submit[,  4])+1]))
recom_prod <- cbind(recom_prod, as.data.table(prod_cols[as.matrix(recom_submit[,  5])+1]))
recom_prod <- cbind(recom_prod, as.data.table(prod_cols[as.matrix(recom_submit[,  6])+1]))
recom_prod <- cbind(recom_prod, as.data.table(prod_cols[as.matrix(recom_submit[,  7])+1]))
recom_prod <- cbind(recom_prod, as.data.table(prod_cols[as.matrix(recom_submit[,  8])+1]))
recom_prod <- cbind(recom_prod, as.data.table(prod_cols[as.matrix(recom_submit[,  9])+1]))
recom_prod <- cbind(recom_prod, as.data.table(prod_cols[as.matrix(recom_submit[, 10])+1]))
recom_prod <- cbind(recom_prod, as.data.table(prod_cols[as.matrix(recom_submit[, 11])+1]))
recom_prod <- cbind(recom_prod, as.data.table(prod_cols[as.matrix(recom_submit[, 12])+1]))
recom_prod <- cbind(recom_prod, as.data.table(prod_cols[as.matrix(recom_submit[, 13])+1]))
recom_prod <- cbind(recom_prod, as.data.table(prod_cols[as.matrix(recom_submit[, 14])+1]))
recom_prod <- cbind(recom_prod, as.data.table(prod_cols[as.matrix(recom_submit[, 15])+1]))
recom_prod <- cbind(recom_prod, as.data.table(prod_cols[as.matrix(recom_submit[, 16])+1]))
recom_prod <- cbind(recom_prod, as.data.table(prod_cols[as.matrix(recom_submit[, 17])+1]))
recom_prod <- cbind(recom_prod, as.data.table(prod_cols[as.matrix(recom_submit[, 18])+1]))
recom_prod <- cbind(recom_prod, as.data.table(prod_cols[as.matrix(recom_submit[, 19])+1]))
recom_prod <- cbind(recom_prod, as.data.table(prod_cols[as.matrix(recom_submit[, 20])+1]))
recom_prod <- cbind(recom_prod, as.data.table(prod_cols[as.matrix(recom_submit[, 21])+1]))
recom_prod <- cbind(recom_prod, as.data.table(prod_cols[as.matrix(recom_submit[, 22])+1]))
recom_prod <- cbind(recom_prod, as.data.table(prod_cols[as.matrix(recom_submit[, 23])+1]))
recom_prod <- cbind(recom_prod, as.data.table(prod_cols[as.matrix(recom_submit[, 24])+1]))
recom_prod <- cbind(recom_prod, as.data.table(prod_cols[as.matrix(recom_submit[, 25])+1]))
recom_prod <- cbind(recom_prod, as.data.table(prod_cols[as.matrix(recom_submit[, 26])+1]))
colnames(recom_prod)[3:26] <- as.vector(sapply("added_products", paste0, 1:24))
#}
recom_prod

library(stringr)
## output submit file
write.table(recom_prod[,3:9], "recom_prod.txt", quote=FALSE, sep=" ", row.names=FALSE, col.names=FALSE)
added_products <- fread("recom_prod.txt", sep=",", head=FALSE)
added_products$V1 <- gsub(" NA", "", added_products$V1)
added_products$V1 <- gsub("NA", "", added_products$V1)
#added_products$V1

colnames(added_products) <- "added_products"
submit_file = cbind(recom_submit[, "ncodpers"], added_products)
head(submit_file)
#write.csv(submit_file, "../submit/submit_20161219_10_01_cri0.01.csv", quote=FALSE, row.names=FALSE)
write.csv(submit_file, "/home/rstudio/Santander/submit/submit_20161219_12_01_cri0.01.csv", quote=FALSE, row.names=FALSE)


# at <- 7
# #paste(recom_prod[1:10, 3], recom_prod[1:10, 4], recom_prod[1:10, 5], recom_prod[1:10, 6], recom_prod[1:10, 7], recom_prod[1:10, 8], recom_prod[1:10, 9], sep=" ")
# added_products = NULL
# #for(i in 1:nrow(recom_prod)){
# for(i in 1:nrow(recom_prod)){
#     added_products = rbind(added_products, paste(recom_prod[i, 3], recom_prod[i, 4], recom_prod[i, 5], recom_prod[i, 6], recom_prod[i, 7], recom_prod[i, 8], recom_prod[i, 9], sep=" "))
# }