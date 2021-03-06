
# Usage: Rscript cleanup.r datafile censorfile imgcensorfile offsetfile outfile
# all arguments are mandatory, in this order: 
#	datafile, tab-separated, as produced by frametot-collect.sh.
#	censorfile, CSV with columns "date", "tube", "loc", "reason", "notes". 
#		Lists dates/locations with image quality too poor to trace accurately.
#	imgcensorfile, csv with columns "img", "reason", "notes".
#		This file lists IMAGES by name, not just date/locations, to remove. Use when e.g. same 
#		location was photographed more than once in a session
# 		and  you want to completely remove all tracings from one of them.
#		If no images to be censored, give filename as "NULL."
#	offsetfile, CSV with columns "tube" and "offset". 
#		Gives length in cm of the portion of the tube projecting out of the soil. 
#		Used here to calculate accurate image depths.
#	outfile, path and filename to which to write the cleaned-up data (as CSV). 
#		If this points to an existing file, it will be overwritten.

require(rhizoFuncs)

args = commandArgs(trailingOnly = TRUE)

raw = read.delim(args[1])
censor = read.csv(args[2])
if(args[3] == "NULL"){ censorimg=NULL }else{ censorimg = read.csv(args[3], stringsAsFactors=FALSE) }
offsets=read.csv(args[4])
outfile = args[5]

raw = make.datetimes(raw)

# Dump everything not from the destructive harvest.
raw = raw[grep("^EFDESTRUCTIVE", raw$Img),]

# Remove entries for images specified in image censor file. 
# Should only be needed when you have multiple images from 
# same day/tube/depth that weren't caught in the pre-tracing cleanup.
if(!is.null(censorimg)){ raw = raw[!(raw$Img %in% censorimg[,1]),] }

# Remove all images that were too low-quality to trace, as specified in location censor file
censor$date = as.Date(censor$date)
raw.to.censor = (
	paste(raw$Date, raw$Tube, raw$Location) 
	%in% paste(censor$date, censor$tube, censor$loc))
raw = droplevels(raw[!raw.to.censor,])
rm(raw.to.censor)

# Sort by order of tracing (required by strip.tracing.dups)
raw = raw[order(raw$MeasDateTime),]

# Drop duplicates: 
# silently if only one is reasonable, 
# with warning if several candidates might be correct.
# Will probably return many, many warnings about multiple calibrations.
# TODO: Catch them instead of flooding stdout, decide how to formally evaluate/fix these.
stripped.by = by(raw, raw$Img, strip.tracing.dups)
stripped = do.call(rbind, stripped.by)
rm(stripped.by)

stripped$Month = months(stripped$Date)
stripped$Block = assign.block(stripped$Tube)
stripped$Species = assign.species(stripped$Tube)
stripped = merge(stripped, offsets[,c("tube", "offset")], by.x="Tube", by.y="tube")
names(stripped)[which(names(stripped)=="offset")] = "Offset" # bleh, inconsistent naming conventions
stripped$Offset[is.na(stripped$Offset)] = 22 # If no better info available, assume 22 cm.
stripped$Depth = loc.to.depth(loc=stripped$Location, offset=stripped$Offset)
stripped$rootvol.mm3.mm2 = with(stripped, 
 	rootvol.perarea(TotVolume.mm3, PxSizeH, PxSizeV))
# normed = normalize.soilvol(stripped) # normalize.soilvol is unfinished and might stay that way

# Make centered predictors
stripped$Date.c = scale(stripped$Date, center=TRUE, scale=FALSE)
stripped$Depth.c = scale(stripped$Depth, center=TRUE, scale=FALSE)

# Done. Save the result.
write.csv(x=stripped, file=outfile, row.names=FALSE)



