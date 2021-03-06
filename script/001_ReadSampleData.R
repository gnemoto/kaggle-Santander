#######################################################################;
# Project           : kaggle Santendar Product Recomendation
#
# Program name      : 001_ReadSampleData.R
#
# Author            : Takashi, SUGAWARA
#
# Date created      : 2016-12-06
#
# Purpose           : Setting Up Environment
#
# Input             : nothing
#
# Output            : nothing 
#
# Revision History  : 
#
#
#######################################################################;


# temp <-
#   read.csv(file = "/home/rstudio/Santendar/indat/train_ver2.csv", header = T)
# str(temp)
# 'data.frame':	13647309 obs. of  48 variables:
# $ fecha_dato           : Factor w/ 17 levels "2015-01-28","2015-02-28",..: 1 1 1 1 1 1 1 1 1 1 ...
# $ ncodpers             : int  1375586 1050611 1050612 1050613 1050614 1050615 1050616 1050617 1050619 1050620 ...
# $ ind_empleado         : Factor w/ 6 levels "","A","B","F",..: 5 5 5 5 5 5 5 5 5 5 ...
# $ pais_residencia      : Factor w/ 119 levels "","AD","AE","AL",..: 38 38 38 38 38 38 38 38 38 38 ...
# $ sexo                 : Factor w/ 3 levels "","H","V": 2 3 3 2 3 2 2 2 2 2 ...
# $ age                  : Factor w/ 121 levels "  2","  3","  4",..: 34 22 22 21 22 22 22 22 23 22 ...
# $ fecha_alta           : Factor w/ 6757 levels "","1995-01-16",..: 6259 5457 5457 5457 5457 5457 5457 5457 5457 5457 ...
# $ ind_nuevo            : int  0 0 0 0 0 0 0 0 0 0 ...
# $ antiguedad           : Factor w/ 259 levels "-999999","      0",..: 8 37 37 37 37 37 37 37 37 37 ...
# $ indrel               : int  1 1 1 1 1 1 1 1 1 1 ...
# $ ult_fec_cli_1t       : Factor w/ 224 levels "","2015-07-01",..: 1 1 1 1 1 1 1 1 1 1 ...
# $ indrel_1mes          : Factor w/ 10 levels "","1","1.0","2",..: 3 2 2 2 2 2 2 2 2 2 ...
# $ tiprel_1mes          : Factor w/ 6 levels "","A","I","N",..: 2 3 3 3 2 3 3 2 3 3 ...
# $ indresi              : Factor w/ 3 levels "","N","S": 3 3 3 3 3 3 3 3 3 3 ...
# $ indext               : Factor w/ 3 levels "","N","S": 2 3 2 2 2 2 2 2 2 2 ...
# $ conyuemp             : Factor w/ 3 levels "","N","S": 1 1 1 1 1 1 1 1 1 1 ...
# $ canal_entrada        : Factor w/ 163 levels "","004","007",..: 155 152 152 151 152 152 152 152 152 152 ...
# $ indfall              : Factor w/ 3 levels "","N","S": 2 2 2 2 2 2 2 2 2 2 ...
# $ tipodom              : int  1 1 1 1 1 1 1 1 1 1 ...
# $ cod_prov             : int  29 13 13 50 50 45 24 50 20 10 ...
# $ nomprov              : Factor w/ 53 levels "","ALAVA","ALBACETE",..: 33 18 18 53 53 49 29 53 22 13 ...
# $ ind_actividad_cliente: int  1 0 0 0 1 0 0 1 0 0 ...
# $ renta                : num  87218 35549 122179 119776 NA ...
# $ segmento             : Factor w/ 4 levels "","01 - TOP",..: 3 4 4 4 4 4 4 4 4 4 ...
# $ ind_ahor_fin_ult1    : int  0 0 0 0 0 0 0 0 0 0 ...
# $ ind_aval_fin_ult1    : int  0 0 0 0 0 0 0 0 0 0 ...
# $ ind_cco_fin_ult1     : int  1 1 1 0 1 1 1 1 1 1 ...
# $ ind_cder_fin_ult1    : int  0 0 0 0 0 0 0 0 0 0 ...
# $ ind_cno_fin_ult1     : int  0 0 0 0 0 0 0 0 0 0 ...
# $ ind_ctju_fin_ult1    : int  0 0 0 0 0 0 0 0 0 0 ...
# $ ind_ctma_fin_ult1    : int  0 0 0 0 0 0 0 0 0 0 ...
# $ ind_ctop_fin_ult1    : int  0 0 0 0 0 0 0 0 0 0 ...
# $ ind_ctpp_fin_ult1    : int  0 0 0 0 0 0 0 0 0 0 ...
# $ ind_deco_fin_ult1    : int  0 0 0 1 0 0 0 0 0 0 ...
# $ ind_deme_fin_ult1    : int  0 0 0 0 0 0 0 0 0 0 ...
# $ ind_dela_fin_ult1    : int  0 0 0 0 0 0 0 0 0 0 ...
# $ ind_ecue_fin_ult1    : int  0 0 0 0 0 0 0 0 0 0 ...
# $ ind_fond_fin_ult1    : int  0 0 0 0 0 0 0 0 0 0 ...
# $ ind_hip_fin_ult1     : int  0 0 0 0 0 0 0 0 0 0 ...
# $ ind_plan_fin_ult1    : int  0 0 0 0 0 0 0 0 0 0 ...
# $ ind_pres_fin_ult1    : int  0 0 0 0 0 0 0 0 0 0 ...
# $ ind_reca_fin_ult1    : int  0 0 0 0 0 0 0 0 0 0 ...
# $ ind_tjcr_fin_ult1    : int  0 0 0 0 0 0 0 0 0 0 ...
# $ ind_valo_fin_ult1    : int  0 0 0 0 0 0 0 0 0 0 ...
# $ ind_viv_fin_ult1     : int  0 0 0 0 0 0 0 0 0 0 ...
# $ ind_nomina_ult1      : int  0 0 0 0 0 0 0 0 0 0 ...
# $ ind_nom_pens_ult1    : int  0 0 0 0 0 0 0 0 0 0 ...
# $ ind_recibo_ult1      : int  0 0 0 0 0 0 0 0 0 0 ...

#divide the original data into train and validation
#random sampling without replacement
# set.seed(1234)
# sample_locks <- sample.int(nrow(temp))
# cutoff       <- as.integer(nrow(temp) * 0.005)
# 
# sample0005 <- temp[sample_locks[1:cutoff], ]
# 
# write.csv(sample0005, file = "indat/sample0005.csv", row.names = FALSE)


smpl0005 <-
read.csv(file = "indat/sample0005.csv", header = T)


colnames(smpl0005) <- c("date",
                        "Customer_code",
                        "Employee_index",
                        "Country_residence",
                        "sex",
                        "Age",
                        "contract_date",
                        "Newcustomer_Index",
                        "Customerseniority",
                        "Primarycustomer",
                        "Lastdateasprimarycustomer",
                        "Customertypeatthebeginningofthemonth",
                        "Customerrelationtypeatthebeginningofthemonth",
                        "Residenceindex",
                        "Foreignerindex",
                        "Spouseindex",
                        "channelusedbythecustomertojoin",
                        "Deceasedindex",
                        "Addrestype",
                        "Provincecode",
                        "Provincename",
                        "Activityindex",
                        "Grossincomeofthehousehold",
                        "Segmentation",
                        "SavingAccount",
                        "Guarantees",
                        "CurrentAccounts",
                        "DerivativeAccount",
                        "PayrollAccount",
                        "JuniorAccount",
                        "MoreParticularAccount",
                        "particularAccount",
                        "particularPlusAccount",
                        "Short_termdeposits",
                        "Medium_termdeposits",
                        "Long_termdeposits",
                        "e_account",
                        "Funds",
                        "Mortgage",
                        "Pensions",
                        "Loans",
                        "Taxes",
                        "CreditCard",
                        "Securities",
                        "HomeAccount",
                        "Payroll",
                        "Pensions",
                        "DirectDebit"
)