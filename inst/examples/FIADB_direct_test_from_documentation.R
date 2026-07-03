

##these are all the examples from FIADB documentation

#Delaware(Statecd = 10)
# Georgia (STATECD = 13)
# Maine (Statecd = 23)
# Minnesota (Statecd = 27)
# Virginia (Statecd = 51)
# Attribute 3   - Area of timberland, in acres
# Attribute 10  - Aboveground biomass of live trees (at least 1 inch d.b.h./d.r.c.), in dry short tons, on forest land (EXPVOL)
# Attribute 208 - Average annual net growth of merchantable bole wood volume of growing-stock trees (at least 5 inches d.b.h.), in cubic feet, on timberland (EXPGROW)
# Attribute 127 - Area change - area forest land both measurements from remeasured plots (EXPCHNG)
# Attribute 311 - Average annual net growth of aboveground biomass of trees (at least 1 inch d.b.h./d.r.c.), in dry short tons, on forest land
# Attribute 16  - Net sawlog wood volume of sawtimber trees, in cubic feet, on forest land (EXPVOL)

VA_GB_est <- GB_est(EVAL_GRP = 512010,ATTRIBUTE_NBR = 10,SCHEMA = "FS_FIADB",dbname = "fiadbnew")

VA_GB_plots <- PLOT_obs(EVAL_GRP = 512010,ATTRIBUTE_NBR = 10,SCHEMA = "FS_FIADB",dbname = "fiadbnew")

VA_PLT_CN <- VA_GB_plots$PLT_CN

# download/extract actual FIADB plot, cond, and tree records -----
PLOT <- GET_record(TABLE_NAME = "PLOT",VAR_NAME = "CN",VAR_VALUES = VA_PLT_CN,dbname = "fiadbnew")
# PLOT table, rename "CN" as "PLT_CN"
PLOT <- PLOT %>% rename(PLT_CN = CN)

COND <- GET_record(TABLE_NAME = "COND",VAR_NAME = "PLT_CN",VAR_VALUES = VA_PLT_CN,dbname = "fiadbnew")
# COND table, rename "CN" as "COND_CN"
COND <- COND %>% rename(COND_CN = CN)

TREE <- GET_record(TABLE_NAME = "TREE",VAR_NAME = "PLT_CN",VAR_VALUES = VA_PLT_CN,dbname = "fiadbnew")
# TREE table, rename "CN" as "TREE_CN"
TREE <- TREE %>% rename(TREE_CN = CN)

# merge PLOT, COND and TREE tables
# right join to preserve all COND records, with duplicates of the PLOT
# variables when there is > 1 condition on a plot
PLOT_COND <- PLOT %>% right_join(COND)
# right join to preserve all TREE records, with duplicates of the PLOT &
# COND variables when there is > 1 tree for a cond/plot combination
PLOT_COND_TREE <- PLOT_COND %>% right_join(TREE)

# sum the tree biomass components: DRYBIO_STEM + DRYBIO_STEM_BARK + DRYBIO_BRANCH
# then multiply for each tree * TPA_UNADJ (to scale to a per acre basis)
PLOT_COND_TREE <- PLOT_COND_TREE %>% mutate(AGB = DRYBIO_STEM +
                                              DRYBIO_STEM_BARK +
                                              DRYBIO_BRANCH,
                          AGB_PER_ACRE = AGB * TPA_UNADJ)

# aggregate AGB_PER_ACRE observations to the plot level using group_by:
# be sure to remove any trees with STATUSCD 0 or 2 (1 is alive and measured)
LIVE_AGB_PLOT <- PLOT_COND_TREE %>% group_by(PLT_CN,STATUSCD) %>%
  summarize(AGB_PER_ACRE = sum(AGB_PER_ACRE)) %>%
  filter(STATUSCD == 1) %>%
  mutate(AGB_TONS_PER_ACRE = AGB_PER_ACRE/2000)

PLOT_COND_TREE %>% filter(PLT_CN == 100167991010478 & is.na(AGB_PER_ACRE))

Attribute = 574171
GA_GB_est <- GB_est(EVAL_GRP = 132010,ATTRIBUTE_NBR = 574171,SCHEMA = "FS_FIADB",dbname = "fiadbnew")
GA2010plots <- PLOT_obs(EVAL_GRP = 132010,ATTRIBUTE_NBR = 574171,SCHEMA = "FS_FIADB",dbname = "fiadbnew")

GA_PLOT_CN = unique(GA2010plots$PLT_CN)
GA_PLOTS <- GET_record("PLOT","CN",GA_PLOT_CN) %>%
  rename(PLT_CN = CN)
GA_COND <- GET_record("COND","PLT_CN",GA_PLOT_CN) %>%
  rename(COND_CN = CN)
length(unique(GA_COND$PLT_CN))

GET_record()


VA_TREE_obs <- TREE_obs(EVAL_GRP = 512018, ATTRIBUTE_NBR = 1202)
VA_TRE_CN <- unique(VA_TREE_obs$TREE_CN)
VA_PLT_CN <- unique(VA_TREE_obs$PLT_CN)

VA_TREE <- GET_record("TREE","CN",VA_TRE_CN) %>%
  rename(TRE_CN = CN)
VA_PLOT <- GET_record("PLOT","CN",VA_PLT_CN) %>%
  rename(PLT_CN = CN)
VA_COND <- GET_record("COND","PLT_CN",VA_PLT_CN)

VA_PLOT <- VA_PLOT[,-grep("_DATE",names(VA_PLOT))]
VA_COND <- VA_COND[,-grep("_DATE",names(VA_COND))]
VA_TREE <- VA_TREE[,-grep("_DATE",names(VA_TREE))]

basepath <- "/mnt/Hal2/rsfast/FVS_calibrate/"
load(file = file.path(basepath,"large.live.trees.Rdata"))
VA_SPECIES <- unique(large.live.trees$SPCD)


VA_PLOT_COND <- VA_PLOT %>% left_join(VA_COND)
VA_PLOT_COND_TREE <- VA_PLOT_COND %>% left_join(VA_TREE)

VA_PLOT_COND_TREE_FILTERED <- VA_PLOT_COND_TREE %>%
  filter(COND_STATUS_CD == 1,
         CONDPROP_UNADJ == 1,
         PLOT_STATUS_CD == 1,
         # SPCD %in% VA_SPECIES,
         STATUSCD == 1,
         PREV_STATUS_CD == 1,
         STDORGCD == 0,
         DSTRBCD1 == 0,
         !is.na(PREVDIA),
         PREVDIA >= 5.0,
         TPA_UNADJ < 7.0)

PLOTS_KEEP <- VA_PLOT_COND_TREE_FILTERED %>% group_by(PLT_CN) %>%
  summarize(Ntrees = length(DIA)) %>%
  filter(Ntrees > 1)

VA_PLOT_COND_TREE_FILTERED_ELEVEN_SPP <- VA_PLOT_COND_TREE_FILTERED %>%
  filter(PLT_CN %in% PLOTS_KEEP$PLT_CN,
         SPCD %in% VA_SPECIES) %>%
  mutate(DELTA =  DIA - PREVDIA)

PLOTS_KEEP <- VA_PLOT_COND_TREE_FILTERED_ELEVEN_SPP %>% group_by(PLT_CN) %>%
  summarize(Ntrees = length(DIA)) %>%
  filter(Ntrees > 1)

VA_PLOT_COND_TREE_FILTERED_ELEVEN_SPP <- VA_PLOT_COND_TREE_FILTERED_ELEVEN_SPP %>%
  filter(PLT_CN %in% PLOTS_KEEP$PLT_CN)

dplyr::select(VA_PLOT_COND_TREE_FILTERED,PREVDIA,DIA) %>% plot(cex=0.1)


large.live.trees <- as.data.frame(ungroup(large.live.trees))
live.tree.plots <- large.live.trees %>% dplyr::select(CN,COUNTYCD,MEASYEAR) %>% distinct()
table(large.live.trees$FORTYPCD)

table(VA_PLOT_RECORDS$MEASYEAR)
table(live.tree.plots$MEASYEAR)

table(VA_TREE_RECORDS$SPCD)
table(large.live.trees$SPCD)

table(VA_PLOT_CN)

llt_CN <- unique(large.live.trees$CN)
llt_TRE_CN <- unique(large.live.trees$TRE_CN)

GET_record('plot','cn',excluded_trees)

length(llt_CN[llt_CN %in% VA_PLOT_CN])
length(llt_TRE_CN[llt_TRE_CN %in% VA_TRE_CN])

excluded_trees <- llt_TRE_CN[!llt_TRE_CN %in% VA_TRE_CN]

ex_trees_full_records <- GET_record('tree','cn',excluded_trees)


#Getting records for plot identifier ‘168258988020004’
GET_record('tree','plt_cn',168258988020004)
#Getting tree record aboveground biomass for Delaware in 2021
AboveG_biomass_DE_TREE_obs <- TREE_obs(EVAL_GRP = 102021, ATTRIBUTE_NBR = 10)
#Getting tree records for  aboveground biomass for Delaware in 2021 and grouping by county and diameter
AboveG_biomass_DE_TREE_obs <- TREE_obs(EVAL_GRP = 102021, ATTRIBUTE_NBR = 10, GRP_BY_ATTRIB =  c('countycd','dia'))
#Getting tree records for aboveground biomass for Delaware in 2021 and filtering ownergroup = 20
AboveG_biomass_DE_TREE_obs <- TREE_obs(EVAL_GRP = 102021, ATTRIBUTE_NBR = 10, FILTER = 'and cond.owngrpcd = 20')
#Getting tree records for  aboveground biomass for Delaware in 2021, grouping by county and filtering having diameter greater than 10 or less than 20
AboveG_biomass_DE_TREE_obs_w_filter <-TREE_obs_w_filter(EVAL_GRP = 102021, ATTRIBUTE_NBR = 10, GRP_BY_ATTRIB = "countycd", VAR_NAMES = 'DIA', VAR_VALUES = c(10,20), VAR_CONDS = c('>=', '<'), VAR_BOOLS =  'AND')
#Getting plot record aboveground biomass for Delaware in 2021
AboveG_biomass_DE_PLOT_obs <- PLOT_obs(EVAL_GRP = 102021, ATTRIBUTE_NBR = 10)
#Getting plot records for aboveground biomass for Delaware in 2021 and grouping by county
AboveG_biomass_DE_PLOT_obs <- PLOT_obs(EVAL_GRP = 192019, ATTRIBUTE_NBR = 10, GRP_BY_ATTRIB = "countycd")
#Getting plot records for aboveground biomass for Delaware in 2021 and filtering ownergroup = 20
AboveG_biomass_DE_PLOT_obs <- PLOT_obs(EVAL_GRP = 102021, ATTRIBUTE_NBR = 10, FILTER = 'and cond.owngrpcd = 20')
#Getting plot records for aboveground biomass for Delaware in 2021, grouping by county and filtering having diameter greater than or equal to 10 or less than 20 inches
AboveG_biomass_DE_PLOT_obs_w_filter <- PLOT_obs_w_filter(EVAL_GRP = 102021, ATTRIBUTE_NBR = 10, GRP_BY_ATTRIB = "countycd", VAR_NAMES = 'DIA', VAR_VALUES = c(10,20), VAR_CONDS = c('>=', '<'), VAR_BOOLS = 'AND')
#Estimating aboveground biomass for Delaware in 2021
AboveG_biomass_DE_GB_est <- GB_est(EVAL_GRP = 102021, ATTRIBUTE_NBR = 10)

#Estimating aboveground biomass for Delaware in 2021 and grouping by county
AboveG_biomass_DE_GB_est <- GB_est(EVAL_GRP = 102021, ATTRIBUTE_NBR = 10,
                                   GRP_BY_ATTRIB = 'countycd')

Area_VA_GB <- GB_est(EVAL_GRP = 512021, ATTRIBUTE_NBR = 3, GRP_BY_ATTRIB=c("FORTYPCD","countycd","stdage"),)

temp <- Area_VA_GB %>% dplyr::filter(TYPGRPCD %in% c(140,160) & COUNTYCD %in% c(25,111,117))
table(temp$STDAGE)

# VAR_NAMES = 'DIA', VAR_VALUES = c(10,20), VAR_CONDS = c('>=', '<'), VAR_BOOLS = 'AND'

Area_VA_GB_4_7 <- GB_est_w_filter(EVAL_GRP = 512021,
                                  ATTRIBUTE_NBR = 3,
                                  GRP_BY_ATTRIB=c("FORTYPCD","countycd","stdage"),
                                  VAR_NAMES = c('STDAGE','COUNTYCD'),
                                  VAR_VALUES = c(4,7), VAR_CONDS = c('>=', '<='), VAR_BOOLS = 'AND')
V_N = c('STDAGE','COUNTYCD')
V_V = list(stdage=c(0,3),countycd=c(25,111,117))
V_C = list(stdage=c('>=', '<='),countycd=c('=','=','='))
V_B = list(stdage='and',countycd=c('or','or'))
Area_VA_GB_0_3 <- GB_est_w_filter(EVAL_GRP = 512021,
                                  ATTRIBUTE_NBR = 3,
                                  GRP_BY_ATTRIB=c("FORTYPCD"),
                                  VAR_NAMES = V_N,
                                  VAR_VALUES = V_V,
                                  VAR_CONDS = V_C,
                                  VAR_BOOLS = V_B)

Area_VA_GB_0_3 <- Area_VA_GB_0_3 %>% dplyr::filter(TYPGRPCD %in% c(140,160) & COUNTYCD %in% c(25,111,117))
fwrite(Area_VA_GB_0_3,"/home/pradtke/Rscripts/temp/Area_VA_GB_0_3.csv")

V_N = c('STDAGE','COUNTYCD')
V_V = list(stdage=c(4,7),countycd=c(25,111,117))
V_C = list(stdage=c('>=', '<='),countycd=c('=','=','='))
V_B = list(stdage='and',countycd=c('or','or'))
Area_VA_GB_4_7 <- GB_est_w_filter(EVAL_GRP = 512021,
                                  ATTRIBUTE_NBR = 3,
                                  GRP_BY_ATTRIB=c("FORTYPCD"),
                                  VAR_NAMES = V_N,
                                  VAR_VALUES = V_V,
                                  VAR_CONDS = V_C,
                                  VAR_BOOLS = V_B)

Area_VA_GB_4_7 <- Area_VA_GB_4_7 %>% dplyr::filter(TYPGRPCD %in% c(140,160) & COUNTYCD %in% c(25,111,117))
fwrite(Area_VA_GB_4_7,"/home/pradtke/Rscripts/temp/Area_VA_GB_4_7.csv")

V_N = c('STDAGE','COUNTYCD')
V_V = list(stdage=c(8,11),countycd=c(25,111,117))
V_C = list(stdage=c('>=', '<='),countycd=c('=','=','='))
V_B = list(stdage='and',countycd=c('or','or'))
Area_VA_GB_8_11 <- GB_est_w_filter(EVAL_GRP = 512021,
                                  ATTRIBUTE_NBR = 3,
                                  GRP_BY_ATTRIB=c("FORTYPCD"),
                                  VAR_NAMES = V_N,
                                  VAR_VALUES = V_V,
                                  VAR_CONDS = V_C,
                                  VAR_BOOLS = V_B)

Area_VA_GB_8_11 <- Area_VA_GB_8_11 %>% dplyr::filter(TYPGRPCD %in% c(140,160) & COUNTYCD %in% c(25,111,117))
fwrite(Area_VA_GB_8_11,"/home/pradtke/Rscripts/temp/Area_VA_GB_8_11.csv")


V_N = c('STDAGE','COUNTYCD')
V_V = list(stdage=c(12,15),countycd=c(25,111,117))
V_C = list(stdage=c('>=', '<='),countycd=c('=','=','='))
V_B = list(stdage='and',countycd=c('or','or'))
Area_VA_GB_12_15 <- GB_est_w_filter(EVAL_GRP = 512021,
                                   ATTRIBUTE_NBR = 3,
                                   GRP_BY_ATTRIB=c("FORTYPCD"),
                                   VAR_NAMES = V_N,
                                   VAR_VALUES = V_V,
                                   VAR_CONDS = V_C,
                                   VAR_BOOLS = V_B)

Area_VA_GB_12_15 <- Area_VA_GB_12_15 %>% dplyr::filter(TYPGRPCD %in% c(140,160) & COUNTYCD %in% c(25,111,117))
fwrite(Area_VA_GB_12_15,"/home/pradtke/Rscripts/temp/Area_VA_GB_12_15.csv")


V_N = c('STDAGE','COUNTYCD')
V_V = list(stdage=c(16,19),countycd=c(25,111,117))
V_C = list(stdage=c('>=', '<='),countycd=c('=','=','='))
V_B = list(stdage='and',countycd=c('or','or'))
Area_VA_GB_16_19 <- GB_est_w_filter(EVAL_GRP = 512021,
                                    ATTRIBUTE_NBR = 3,
                                    GRP_BY_ATTRIB=c("FORTYPCD"),
                                    VAR_NAMES = V_N,
                                    VAR_VALUES = V_V,
                                    VAR_CONDS = V_C,
                                    VAR_BOOLS = V_B)

Area_VA_GB_16_19 <- Area_VA_GB_16_19 %>% dplyr::filter(TYPGRPCD %in% c(140,160) & COUNTYCD %in% c(25,111,117))
fwrite(Area_VA_GB_16_19,"/home/pradtke/Rscripts/temp/Area_VA_GB_16_19.csv")

V_N = c('STDAGE','COUNTYCD')
V_V = list(stdage=c(20,50),countycd=c(25,111,117))
V_C = list(stdage=c('>=', '<='),countycd=c('=','=','='))
V_B = list(stdage='and',countycd=c('or','or'))
Area_VA_GB_20_50 <- GB_est_w_filter(EVAL_GRP = 512021,
                                    ATTRIBUTE_NBR = 3,
                                    GRP_BY_ATTRIB=c("FORTYPCD"),
                                    VAR_NAMES = V_N,
                                    VAR_VALUES = V_V,
                                    VAR_CONDS = V_C,
                                    VAR_BOOLS = V_B)

Area_VA_GB_20_50 <- Area_VA_GB_20_50 %>% dplyr::filter(TYPGRPCD %in% c(140,160) & COUNTYCD %in% c(25,111,117))
fwrite(Area_VA_GB_20_50,"/home/pradtke/Rscripts/temp/Area_VA_GB_20_50.csv")



summary(Area_VA_GB)


#Estimating aboveground biomass for Delaware in 2021 and filtering ownergroup = 20
AboveG_biomass_DE_GB_est <- GB_est(EVAL_GRP = 102021, ATTRIBUTE_NBR = 10,
                                   FILTER = 'and cond.owngrpcd = 20')

#Estimating aboveground biomass for Delaware in 2021, grouping by county and filtering having diameter greater than 10 or less than 20
AboveG_biomass_DE_GB_est_w_filter <- GB_est_w_filter(EVAL_GRP = 102021, ATTRIBUTE_NBR = 10, GRP_BY_ATTRIB = "countycd", VAR_NAMES = 'DIA', VAR_VALUES = c(10,20), VAR_CONDS = c('>=', '<'), VAR_BOOLS = 'AND')

#When there is only one VAR_NAMES AND VAR_VALUES
create_filter( VAR_NAMES = 'DIA', VAR_VALUES = 10, VAR_CONDS = '>')
#When there is only one VAR_NAMES and more than one VAR_VALUES
create_filter(VAR_NAMES = 'DIA', VAR_VALUES = c(10,30), VAR_CONDS = c('>', '<'), VAR_BOOLS = 'AND')
#When there is more than one VAR_NAMES and only one VAR_VALUES for each VAR_NAMES
create_filter(VAR_NAMES = c('DIA', 'OWNGRPCD'), VAR_VALUES = list(DIA = 10, OWNGRPCD = 20), VAR_CONDS = list(DIA = '>',OWNGRPCD = '='), VAR_BOOLS = list(DIA = NA, OWNGRPCD = NA))
#When there is more than one VAR_NAMES and only one VAR_VALUES for one VAR_NAME and more than one VAR_VALUES for the other one
create_filter(VAR_NAMES = c('DIA', 'OWNGRPCD'), VAR_VALUES = list(DIA = 10, OWNGRPCD = c(10,20)), VAR_CONDS = list(DIA = '>',OWNGRPCD = '='), VAR_BOOLS = list(DIA = NA, OWNGRPCD = 'OR'))
#When there is more than one VAR_NAMES and more than one VAR_VALUES for each VAR_NAMES
create_filter(VAR_NAMES = c('DIA', 'OWNGRPCD'),
              VAR_VALUES = list(DIA = c(5,12), OWNGRPCD = c(10,20,30)),
              VAR_CONDS = list(DIA = c('>=','<'), OWNGRPCD = '='),
              VAR_BOOLS = list(DIA = 'AND', OWNGRPCD = 'OR'))




