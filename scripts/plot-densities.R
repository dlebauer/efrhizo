
# Diagnostics to answer the question
# "What's up with these small-volume outliers in 2010?"
# The answer, I fear, is probably "bad tracing."

library("ggplot2")

# strpall is generated by scripts/stat-prep.R

sp_yr_mean_med = subset(strpall, rootvol.mm3.mm2 > 0)
	%>% group_by(Year, Species)
	%>% select(TotLength.mm, TotAvgDiam.10ths.mm, rootvol.mm3.mm2)
	%>% summarise_each(funs(mean(log(.)), median(log(.))))


sp_yr_logdens = function(var){
	print(
		ggplot(subset(strpall, rootvol.mm3.mm2 > 0),
			aes(x=log(get(var))))
		+geom_density(adjust=0.2)
		+facet_grid(Year~Species, scales="free")
		+xlab(paste0("log(", var, ")"))
		+geom_vline(
			aes(xintercept=get(paste0(var, "_median"))),
			data=sp_yr_mean_med)
		+theme_bw()
	)
}




sp_yr_logdens_hist = function(var){
 	print(
 		ggplot(strpall %>% filter(rootvol.mm3.mm2 > 0),
 			aes(x=log(get(var))))
 		+geom_histogram(aes(y=..density..), binwidth=0.2)
         +geom_density(adjust=1, color="blue")
 		+facet_grid(Year~Species)
 		+xlab(paste0("log(", var, ")"))
 		+theme_minimal()
 	)
 }

for (var in c("TotLength.mm", "TotAvgDiam.10ths.mm", "rootvol.mm3.mm2")){
	quartz()
	sp_yr_logdens(var)
	quartz()
	sp_yr_logdens_hist(var)
}