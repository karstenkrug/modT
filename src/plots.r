################################################################################################################
## Filename: plots.r
## Created: February 06, 2015
## Author(s): Karsten Krug
##
## Purpose: plot functions for Protigy app.
##
################################################################################################################



#################################################################################
##     Heatmap of expression values combining all of the results from all tests
##
##
##
#################################################################################
plotHM <- function(res,
                   grp,
                   grp.col,
                   grp.col.legend,
                   hm.clust,
                   hm.title,
                   hm.scale,
                   style,
                   hc.method='ward.D2',
                   hc.dist='pearson',
                   ##filename=NA,
                   fn=NA,
                   cellwidth=NA, 
                   cellheight=NA, 
                   max.val=NA, 
                   fontsize_col, 
                   fontsize_row, 
                   height=height, 
                   width=width,
                   anno.col,
                   anno.col.color,
                   show.rownames=T,
                   show.colnames=T,
                   #cdesc=NULL,
                   #cdesc.grp=NULL,
                   plotly=F,
                   verbose=T,
                   ...){
  
  if(verbose)
    cat('\n-- plotHM --\n')
  
  ## convert to data matrix
  res <- data.matrix(res)
  res <- res[, names(grp[order(grp)])]
  
  
  
  #########################################
  ## different 'styles' for different tests
  ## - reorder columns
  ## - gaps between experiments
  if(style == 'One-sample mod T'){
    #res <- res[, names(grp[order(grp)])]
    gaps_col=cumsum(table(grp[order(grp)]))
    gapsize_col=20
  }
  if(style == 'Two-sample mod T'){
    #res <- res[, names(grp[order(grp)])]
    gaps_col=NULL
    gapsize_col=0
  }
  if(style == 'mod F' | style == 'none'){
    #res <- res[, names(grp[order(grp)])]
    
    gaps_col=NULL
    gapsize_col=0
  }
  
  ##########################################
  ##          cluster
  ##########################################
  hc.tmp <- HCluster(res, hm.clust = hm.clust, hc.method=hc.method, hc.dist=hc.dist)
  Rowv <- hc.tmp$Rowv
  Colv <- hc.tmp$Colv
  #rowv.dist <- hc.tmp$rowv.dist
  #colv.dist <- hc.tmp$colv.dist
  na.idx.row <- hc.tmp$na.idx.row
  na.idx.col <- hc.tmp$na.idx.col
  
  # update result table
  if(length(na.idx.col) > 0)
    res <- res[, -na.idx.col]
  if(length(na.idx.row) > 0)
    res <- res[-na.idx.row, ]
  
  #save(anno.col, anno.col.color, res, Rowv, Colv, file='tmp.RData')
  
  #########################################
  ## scaling
  if(hm.scale == 'row')
    res <- t(apply(res, 1, function(x)(x-mean(x, na.rm=T))/sd(x, na.rm=T)))
  if(hm.scale == 'column')
    res <- apply(res, 2, function(x)(x-mean(x, na.rm=T))/sd(x, na.rm=T))
  
  
  #########################################
  ## capping
  if(!is.na(max.val)){
    res[ res < -max.val ] <- -max.val
    res[ res > max.val ] <- max.val
  }
  #########################################
  ## min/max value
  max.val = ceiling( max( abs(res), na.rm=T) )
  min.val = -max.val
  
  ##########################################
  ## colors
  color.breaks = seq( min.val, max.val, length.out=12 )
  color.hm = rev(brewer.pal (length(color.breaks)-1, "RdBu"))
  
  if(hm.clust %in% c('row', 'both'))
    margins <- c(150, 50, 150, 150) # heatmaply
  else
    margins <- c(50, 50, 150, 150) # heatmaply
  
  ##############################################
  ## heatmap title
  if(length(na.idx.row) > 0| length(na.idx.col) > 0)
    hm.title = paste(hm.title, '\nremoved rows / columns: ', length(na.idx.row), ' / ' , length(na.idx.col), sep='')
  
  ## indicate scaling in the title
  hm.title <- paste(hm.title, '\nscaling: ',hm.scale, sep='')
  
  hm.rownames <- chopString(rownames(res), STRLENGTH)
  
  
  ############################################
  ## plot the heatmap
  if(!plotly){
    # pheatmap
    #View(res)
    pheatmap(res, fontsize_row=fontsize_row, fontsize_col=fontsize_col,
             cluster_rows=Rowv, cluster_cols=Colv, border_col=NA, col=color.hm,  main=hm.title, 
             annotation_col=anno.col, annotation_colors=anno.col.color, labels_col=chopString(colnames(res), STRLENGTH), 
             breaks=color.breaks,  cellwidth=cellwidth, cellheight=cellheight, gaps_col=gaps_col, gapsize_col=gapsize_col, 
             labels_row=hm.rownames, na_col='black', scale='none', 
             annotation_names_col = F, height=height, width=width,
             show_rownames = show.rownames, show_colnames = show.colnames, ...)
  } else {
    
    #save(anno.col.color, anno.col, res, grp, file='tmp.RData')
    
    # heatmaply
    #names(anno.col.color) <- NULL
    #anno.col.color <- unlist(anno.col.color)
    #cat(anno.col.color)
    #anno.col.color <- anno.col.color[grp]
    
    anno.col.color <-unlist(lapply(colnames(anno.col), function(x) unlist(anno.col.color[[x]])))
    ##View(anno.col.color)
    show.rownames=F
    if(show.rownames)
      heatmaply(res, labCol = NA, margins = margins, Colv = Colv, Rowv = Rowv, colors = color.hm, na.value = 'black', main=hm.title,
              limits=c(min.val, max.val), col_side_colors = anno.col, col_side_palette = anno.col.color,
              colorbar_xanchor = 'right', colorbar_yanchor = 'bottom', row_dend_left = TRUE,
              plot_method = "ggplot", seriate = 'mean', key=FALSE, hide_colorbar = T) 
    if(!show.rownames)
      heatmaply(res, labCol = NA, labRow = NA, margins = margins, Colv = Colv, Rowv = Rowv, colors = color.hm, na.value = 'black', main=hm.title,
                limits=c(min.val, max.val), col_side_colors = anno.col, col_side_palette = anno.col.color,
                colorbar_xanchor = 'right', colorbar_yanchor = 'bottom', row_dend_left = TRUE,
                plot_method = "ggplot", seriate = 'mean', key=FALSE, hide_colorbar = T) 
  }

  #if(verbose)
  #  cat('\n-- plotHM exit--\n')
  }

## #####################################################################
##
##   - create column annotation object for the heatmap
##   - create color palettes for each data track
##
## ######################################################################
cdesc.colors <- function(cdesc, cdesc.grp, grp.col.legend){
  
  # reorder
  #save(cdesc.grp, cdesc, grp.col.legend, file='tmp.RData')
  
  ## remove 'id'
  #if('id' %in% rownames(cdesc))
  #  cdesc <- cdesc[ -which(rownames(cdesc) == 'id'), ] 
  
  anno.col <- cdesc[, c( colnames(cdesc)[-which(colnames(cdesc) == cdesc.grp)] , colnames(cdesc)[which(colnames(cdesc) == cdesc.grp)])]
  
  # COLORS for class vector used for marker selection
  anno.col.color=list(grp.col.legend)
  names(anno.col.color) <- cdesc.grp
  
  # COLORS for annotation tracks
  # all brewer.pals
  all.brews <- brewer.pal.info
  
  # annotation track names, without the one used for marker selection
  anno.track.names <- setdiff(colnames(anno.col), cdesc.grp) 
  for(i in  1:length(anno.track.names)){
    # track name
    anno.track.tmp <- anno.track.names[i]
    
    # brewer palette
    brew.tmp <- all.brews[min(i, nrow(all.brews)), ]
    brew.tmp.name <- rownames(all.brews)[min(i, nrow(all.brews)) ]
    
    # number of category levels
    n.cat <- length(unique(anno.col[, anno.track.tmp]))
    
    if(n.cat > brew.tmp[['maxcolors']]){
      brew.tmp <-  colorRampPalette(c('grey90', 'grey10'))(n.cat)
    } else {
      # list of color palettes
      brew.tmp <- brewer.pal(n.cat, brew.tmp.name)
      brew.tmp <- brew.tmp[1:n.cat]
    }
    names(brew.tmp) <- unique(anno.col[, anno.track.tmp])
    
    anno.col.color <- append(anno.col.color, list( brew.tmp))
    names(anno.col.color)[ length(anno.col.color) ] <- anno.track.tmp
    
  }   
  return(list(anno.col.color=anno.col.color, anno.col=anno.col))
}

## #########################################################
## - function to perform hierarchical clustering
## - robustified against missing values
## - used by function plotHM and PlotFAN
##
##  res       - (filtered) data tables
##  hm.clust  - 'row', 'column', 'both'
##  hc.method - method, passed to 'hclust'
##  hc.dist   - distance metric, passed to 'dist'
HCluster <- function(res, hm.clust, hc.method='ward.D2', hc.dist=c('euclidean', 'pearson')){
  # res.org <- res
  na.idx.row <- na.idx.col <- NULL
  
  hc.dist <- match.arg(hc.dist)
  cor.dist <- ifelse(hc.dist == 'pearson', T, F)
  
  ## remove features not quantified at all
  #valid.idx.row <- apply(res, 1, function(x) ifelse(sum(is.na(x)/length(x)) < 1, T, F) )
  #res <- res[valid.idx.row, ]  

  #########################
  ## column clustering
  if(hm.clust == 'column'){
    Rowv=FALSE
    rowv.dist = NULL
    #colv.dist = dist(t(res), method=hc.dist, diag=T, upper=T)
    
    if(cor.dist)
      colv.dist <- as.matrix(as.dist(1- cor(res, use='pairwise.complete')))
    else
      colv.dist = dist(t(res), method=hc.dist)
    
    na.idx.col <- which(apply(as.matrix(colv.dist), 1, function(x) sum(is.na(x))) > 0)
    
    if(length(na.idx.col)> 0){
      colv.dist <- colv.dist[-na.idx.col, ]
      colv.dist <- colv.dist[, -na.idx.col]
    }
    #Colv=hclust(as.dist(colv.dist), method=hc.method)
    Colv = fastcluster::hclust(as.dist(colv.dist), method=hc.method)
    
    ## #################################
    ## row clustering
  } else if( hm.clust == 'row'){
    
    #rowv.dist <- as.matrix(dist(res, method=hc.dist, diag=T, upper=T))
    if(cor.dist)
      rowv.dist <- as.matrix(as.dist(1- cor(t(res), use='pairwise.complete')))
    else
      rowv.dist <- as.matrix(dist(res, method=hc.dist))
    
    na.idx.row <- which(apply(as.matrix(rowv.dist), 1, function(x) sum(is.na(x))) > 0)
    if(length(na.idx.row)> 0){
      rowv.dist <- rowv.dist[-na.idx.row, ]
      rowv.dist <- rowv.dist[, -na.idx.row]
    }
    #save(rowv.dist, res, file='tmp.RData')
    #Rowv=hclust(as.dist(rowv.dist), method=hc.method)
    Rowv= fastcluster::hclust(as.dist(rowv.dist), method=hc.method)
    Colv=FALSE
    colv.dist = NULL
    
    ## row and column clustering
  } else if(hm.clust == 'both'){
    
    ## row clustering
    #rowv.dist <- as.matrix(dist(res, method=hc.dist, diag=T, upper=T))
    if(cor.dist)
      rowv.dist <- as.matrix(as.dist(1- cor(t(res), use='pairwise.complete')))
    else
      rowv.dist <- as.matrix(dist(res, method=hc.dist))
    
    na.idx.row <- which(apply(as.matrix(rowv.dist), 1, function(x) sum(is.na(x))) > 0)
    if(length(na.idx.row)> 0){
      rowv.dist <- rowv.dist[-na.idx.row, ]
      rowv.dist <- rowv.dist[, -na.idx.row]
    }
    Rowv=fastcluster::hclust(as.dist(rowv.dist), method=hc.method)
    
    ## column clustering
    #colv.dist = dist(t(res), method=hc.dist, diag=T, upper=T)
    if(cor.dist)
      colv.dist <- as.matrix(as.dist(1- cor(res, use='pairwise.complete')))
    else
      colv.dist = dist(t(res), method=hc.dist)
    
    na.idx.col <- which(apply(as.matrix(colv.dist), 1, function(x) sum(is.na(x))) > 0)
    if(length(na.idx.col)> 0){
      colv.dist <- colv.dist[-na.idx.col, ]
      colv.dist <- colv.dist[, -na.idx.col]
    }
    Colv=fastcluster::hclust(as.dist(colv.dist), method=hc.method)
  } else {
    Rowv=Colv=FALSE
    rowv.dist <- colv.dist <- NULL
  }
  
  #save(res, Rowv, Colv, colv.dist, rowv.dist, na.idx.col, na.idx.row, file='cluster.RData')
  return(list(Rowv=Rowv, rowv.dist=rowv.dist, colv.dist=colv.dist, Colv=Colv, na.idx.col=na.idx.col, na.idx.row=na.idx.row))
}


#######################################################
##
##
## changelog: 20140722 implementation
##            20141104 fixed names for x-axis
##            20150209 parameter 'grid'
##            20151027 parameter 'grid.at'
##            20160308 replaced axes by xaxis and yaxis
##            20170303 'vio.wex'
#######################################################
fancyBoxplot <- function(x, 
                         ylim=NULL, 
                         xlim=NULL, 
                         at=NULL, 
                         col="grey80", 
                         vio.alpha=100, 
                         box.border="black", 
                         box.pch=20, 
                         drawRect=F, 
                         xlab="", 
                         ylab="", 
                         xaxis=T, 
                         yaxis=T, 
                         main="boxplot", 
                         names=NULL, 
                         las=1,
                         cex.names=1, 
                         grid=T, 
                         grid.at=NULL, 
                         vio.wex=1.2, 
                         show.numb=c('none', 'median', 'mean', 'median.top', 'median.bottom'), 
                         numb.cex=.6, 
                         numb.col='black', 
                         numb.pos=3, 
                         ...){
  
  p_load(vioplot)
  
  show.numb <- match.arg(show.numb)
  
  ####################################
  ## names for x-axis
  if(is.null(names) & is.null(names(x)))
    names.x=1:length(x)
  else if(!is.null(names(x)))
    names.x=names(x)
  else
    names.x=names
  
  
  ##################################
  # remove NAN/Inf
  x <- lapply(x, function(x) {x=na.omit(x);x=x[is.finite(x)]})
  
  # ylim
  if(is.null(ylim))
    ylim=range(unlist(x))
  
  ##################################
  if(length(x) == 1){
    x = unlist(x)
    plot(NA, axes=F, xlab=xlab, ylab=ylab, ylim=ylim, type="n", main=main, ...)
    
    vioplot( x, add=T, at=1, col=col, drawRect=drawRect, wex=vio.wex, ...)
    boxplot( x, add=T, at=1, border=box.border, pch=box.pch, ...)
  }
  
  #################################
  if(length(x) > 1){
    
    ## xlim
    if(is.null(xlim))
      xlim=c(0.5, length(x)+0.5)
    
    ## at
    if(is.null(at))
      at=1:length(x)
    if( !is.null(at) ){
      xlim=c(0, max(at)+1)
    }
    
    ## colour
    if(length(col) == 1)
      col=rep(col, length(x) )
    
    ## initialize plot
    plot(NA, axes=F, ylim=ylim, xlim=xlim, type="n", xlab=xlab, ylab=ylab, main=main, ...)
    
    ## axes
    if(xaxis){
      axis(1, at=at, labels=names.x, las=las, cex.axis=cex.names)
    }
    if(yaxis){
      axis(2, las=2)
    }
    ## grid
    if(grid){
      if(is.null(grid.at))
        abline( h=floor(ylim[1]):ceiling(ylim[2]), col='grey', lty='dotted' )
      else
        abline( h=grid.at, col='grey', lty='dotted' )
      
    }
    
    ## plot each box/violin
    for(i in 1:length(x)){
      
      if(length(x[[i]]) > 0){
        
        vioplot( x[[i]], add=T, at=at[i], col=my.col2rgb(col[i], vio.alpha), drawRect=drawRect, border=F, wex=vio.wex,...)
        boxplot( x[[i]], add=T, at=at[i], border=box.border, pch=box.pch, col=col[i], axes=F,...)
        
        if(show.numb=='median')
          text(at[i], median(x[[i]]), round(median(x[[i]]),2), pos=numb.pos, cex=numb.cex, offset=0.1, col=numb.col )
        if(show.numb=='mean')
          text(at[i], mean(x[[i]]), round(median(x[[i]]),2), pos=numb.pos, cex=numb.cex, offset=0.1, col=numb.col )
        if(show.numb=='median.top')
          text(at[i], ylim[2], round(median(x[[i]]),2), pos=1, cex=numb.cex, offset=0.1, col=numb.col )
        if(show.numb=='median.bottom')
          text(at[i], ylim[1], round(median(x[[i]]),2), pos=3, cex=numb.cex, offset=0.1, col=numb.col )
        
        ##text(at[i], mean(x[[i]]), "*", adj=c(0,0) )
      }
      
    }
    
  }
  
}


###################################################
## correlation matrix
###################################################
calculateCorrMat <- function(tab,
                            # id.col,
                             grp,
                             lower=c('pearson', 'spearman', 'kendall', 'pcor'), 
                             upper=c('pearson', 'spearman', 'kendall', 'pcor'),
                             verbose=T){
  if(verbose)
    cat('\n-- calculateCorrMat --\n')
 
  
  ## table
  #tab <- tab[, setdiff(colnames(tab), id.col)]
  tab <- tab[, names(grp)]
  
  ###########################
  ## calculate correlations
  ## withProgress({
  ##     setProgress(message = 'Processing...', detail= 'Calculation correlations')
  cm.upper <- cor(tab, use='pairwise', method=match.arg(upper))
  cm.lower <- cor(tab, use='pairwise', method=match.arg(lower))
  ##})
  
  ###########################
  ## initialize correlation matrix
  cm <- matrix(NA, ncol=ncol(cm.upper),nrow=nrow(cm.upper), dimnames=dimnames(cm.upper))
  cm[ lower.tri(cm, diag=T) ] <- cm.lower[lower.tri(cm.lower, diag=T)]
  cm[ upper.tri(cm, diag=F) ] <- cm.upper[upper.tri(cm.upper, diag=F)]
 
  
  return(cm)
  
}

plotCorrMat <- function(#tab,
                        #id.col,
                        cm,
                        grp,
                        grp.col.legend,
                        filename=NA, 
                        lower=c('pearson', 'spearman', 'kendall', 'pcor'), 
                        upper=c('pearson', 'spearman', 'kendall', 'pcor'), 
                        trans=F, 
                        display_numbers=T,
                        verbose=T,
                        width=12,
                        height=12
                      ){
  if(verbose)
    cat('\n-- plotCorrMat --\n')
  
  ## table
  #tab <- tab[, setdiff(colnames(tab), id.col)]
  #tab <- tab[, names(grp)]
  
  ## transpose
  #if(trans)
  #  tab=t(tab)
  
  ###########################
  ## calculate correlations
  ## withProgress({
  ##     setProgress(message = 'Processing...', detail= 'Calculation correlations')
  #cm.upper <- cor(tab, use='pairwise', method=match.arg(upper))
  #cm.lower <- cor(tab, use='pairwise', method=match.arg(lower))
  ##})
  ###########################
  ## initialize correlation matrix
  #cm <- matrix(NA, ncol=ncol(cm.upper),nrow=nrow(cm.upper), dimnames=dimnames(cm.upper))
  #cm[ lower.tri(cm, diag=T) ] <- cm.lower[lower.tri(cm.lower, diag=T)]
  #cm[ upper.tri(cm, diag=F) ] <- cm.upper[upper.tri(cm.upper, diag=F)]
  
  
  
  ## colors
  color.breaks = seq(-1, 1, length.out=20)
  color.hm=colorRampPalette(c('blueviolet','blue','cyan', 'aliceblue', 'white' , 'blanchedalmond', 'orange', 'red', 'darkred'))(length(color.breaks))
  
  ## gaps between groups
  gaps.column=cumsum(table(grp))
  gaps.row=gaps.column
  
  ## annotation of rows/columns
  anno=data.frame(Group=grp)
  anno.color=list(Group=grp.col.legend)
  
  Rowv=F
  Colv=F
  
  cm <- cm %>% data.matrix()
  #head(cm)
  #heatmaply_cor(cm, labRow = NA, labCol = NA, 
  #              col_side_colors = anno, 
  #              row_side_colors = anno, 
  #              Rowv=Rowv, Colv=Colv, 
  #              col_side_palette=grp.col.legend, 
  #              row_side_palette=grp.col.legend, 
  #              color=color.hm,
  #              draw_cellnote=display_numbers,
  #              cellnote_textposition='middle center',
  #              file=filename)
  
  ##setHook("grid.newpage", function() pushViewport(viewport(x=1,y=1,width=0.9, height=0.9, name="vp", just=c("right","top"))), action="prepend")
  setHook("grid.newpage", function() pushViewport(viewport(x=1,y=1,width=0.9, height=0.9, name="vp", just=c("right","top"))))
  #if(trans)
  #  pheatmap(cm, fontsize_row=10, fontsize_col=10,
  #           cluster_rows=Rowv, cluster_cols=Colv, border_col=NA, col=color.hm, filename=filename, labels_col=chopString(colnames(cm), STRLENGTH), labels_row=chopString(rownames(cm), STRLENGTH), main='', display_numbers=display_numbers, fontsize_number=100/ncol(cm)+10, breaks=color.breaks, width=width, height=height)
  #else
  pheatmap(cm, fontsize_row=10, fontsize_col=10,
             cluster_rows=Rowv, cluster_cols=Colv, border_col=NA, col=color.hm, filename=filename, labels_col=chopString(colnames(cm), STRLENGTH), labels_row=chopString(rownames(cm), STRLENGTH), main='', annotation_col=anno, annotation_colors=anno.color,  annotation_row=anno, display_numbers=display_numbers, fontsize_number=100/ncol(cm)+10, breaks=color.breaks, gaps_col=gaps.column, gaps_row=gaps.row, width=width, height=height)
  setHook("grid.newpage", NULL, "replace")
  
  ## add corr coeff
  grid.text(paste(match.arg(upper)), y=.995, x=.4, gp=gpar(fontsize=25))
  grid.text(paste(match.arg(lower)), x=-0.01, rot=90, gp=gpar(fontsize=25))


  if(verbose)
      cat('\n-- plotCorrMat exit--\n')
    
}



## ##############################################################################################
##
##                                 FANPLOT
##  - circular visualization of dendrograms
##  - based on hierarchical clustering of samples
## ##############################################################################################
plotFAN <-function(res, grp, grp.col, grp.col.legend, show.tip.label=T, tip.cex=0.7, tip.pch = '*') {
  
  ## convert to data matrix
  res <- data.matrix(res)
  res <- res[, names(grp[order(grp)])]
  
  
  ## cluster 
  hc.tmp <- HCluster(res, hm.clust = 'column')
  
  #dist <- hc.tmp$colv.dist
  hc <- hc.tmp$Colv
  dend <- as.dendrogram(hc)
  phyl <- as.phylo(dend)
  if(show.tip.label)
    phyl$tip.label <- grp
  else
    phyl$tip.label <- rep(tip.pch, length(phyl$tip.label))
  
  # ##########################  
  # plot
  par(mfrow=c(1,2))
  plot(phyl, type = 'fan', label.offset = 1, cex=tip.cex, tip.color=grp.col, main='', no.margin=T)
  plot.new()
  plot.window(xlim=c(0,1), ylim=c(0, 1))
  legend('center', legend=names(grp.col.legend), col=grp.col.legend, pch=tip.pch, pt.cex = 3, 
         ncol=ifelse( length(grp.col.legend) > 10, 2, 1), 
         bty='n', 
         cex=2
  )
  par(mfrow=c(1,1))
}


###################################################################
##
##       generate the boxplots under the 'QC' tab
##
###################################################################
makeBoxplot <- function(tab, id.col, grp, grp.col, grp.col.leg, legend=T, cex.lab=1.5, mar=c(4,12,2,4)){
  
  cat('\n-- makeBoxplot --\n')
  
  ## table
  tab <- tab[, setdiff(colnames(tab), id.col)]
  
  ##	cat(id.col)
  
  ##########################################
  ## order after groups
  ord.idx <- order(grp)
  grp <- grp[ord.idx]
  tab <- tab[, ord.idx]
  grp.col <- grp.col[ ord.idx]
  
  
  at.vec=1:ncol(tab)
  ##########################################
  ## plot
  par(mar=mar)
  boxplot(tab, pch=20, col='white', outline=T, horizontal=T, las=2, xlab=expression(log[2](ratio)), border=grp.col, at=at.vec, axes=F, main='', cex=2, xlim=c(0, ifelse(legend, ncol(tab)+2, ncol(tab)) ))
  ##legend('top', legend=names(grp.col.leg), ncol=2, bty='n', border = names(grp.col.leg), fill='white', cex=1.5)
  if(legend)
    legend('top', legend=names(grp.col.leg), ncol=length(grp.col.leg), bty='n', border = grp.col.leg, fill=grp.col.leg, cex=cex.lab)
  ##legend('top', legend=c(input$label.g1, input$label.g2), ncol=2, bty='n', border = c('grey10', 'darkblue'), fill='white', cex=1.5, lwd=3)
  mtext( paste('N=',unlist(apply(tab,2, function(x)sum(!is.na(x)))), sep=''), at=at.vec, side=4, las=2, adj=0, cex.lab=cex.lab)
  axis(1)
  axis(2, at=at.vec, labels=chopString(colnames(tab), STRLENGTH), las=2, cex=cex.lab)
  
  cat('\n-- makeBoxplot exit --\n')
}

## #########################################################################################
## plotly version
makeBoxplotly <- function(tab, id.col, grp, grp.col, verbose=T, title='boxplot') {
  
  if(verbose)
    cat('\n-- makeBoxplotly --\n')
  
  ## table
  tab <- tab[, setdiff(colnames(tab), id.col)]
  
  ##	cat(id.col)
  
  ##########################################
  ## order after groups
  ord.idx <- order(grp)
  grp <- grp[ord.idx]
  tab <- tab[, names(grp)]
  grp.col <- grp.col[ ord.idx]
  
  
  ##########################################
  ## plot
  #p <-  plot_ly(tab, y=tab[, 1],  type='box', name=colnames(tab)[1], marker = list(color = grp.col[1]))
  p <-  plot_ly(tab, x=tab[, 1],  type='box', name=colnames(tab)[1], marker = list(color = grp.col[1]), line=list( color=grp.col[1]), hoverinfo='name+x', hoverlabel=list(namelength=STRLENGTH)  )
  for(i in 2:ncol(tab))
    p <- p %>% add_trace(x=tab[, i], name=colnames(tab)[i], marker=list(color = grp.col[i] ), line=list( color=grp.col[i]))
  p <- p %>%  layout(showlegend = FALSE, title=title, yaxis=list(visible=T) )# %>% yaxis(visible=F)
  return(p)
}

#################################################################################################
##                     multiscatterplot using hexagonal binning
## - mat    numerical matrix of expression values, rows are features, columns are samples
##
#################################################################################################
my.multiscatter <- function(mat, cm, hexbin=30, hexcut=5, 
                            #cor=c('pearson', 'spearman', 'kendall'), 
                            repro.filt=NULL, 
                            grp, 
                            grp.col.legend, 
                            define.max=F,
                            robustify=T,
                            max.val=3, 
                            min.val=-3,
                            update){
  
  # trigger 'update' button
  trigger <- update
  #cat(update,'\n')
  ## cor method
  #corm = match.arg(cor)
  
  ## correlation
  #cm = cor(mat, use='pairwise.complete', method=corm)
  
  ## number of samples to compare
  #N = ncol(mat)
  N= ncol(cm)
  
  ## define limits
  if(robustify){
      lim <- max(quantile( abs(mat), c(0.9999), na.rm=T ), na.rm=T)
      lim=c(-lim, lim)
  }
  if(define.max) {
      lim <-c(min.val, max.val)
  } 
  if(!robustify & !define.max) {
      lim=max( abs( mat ), na.rm=T )
      lim=c(-lim, lim)
  }
  
  
  ###########################################################################
  ## help function to set up the viewports
  ## original code from:  http://www.cookbook-r.com/Graphs/Multiple_graphs_on_one_page_(ggplot2)/
  multiplot <- function(plots, cols=1) {
    ## Make a list from the ... arguments and plotlist
    ##plots <- c(list(...))
    ## number of plots
    numPlots = length(plots)
    ## layout matrix
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)), ncol = cols, nrow = ceiling(numPlots/cols))
    ## Set up the page
    grid.newpage()
    ## grid layout
    la <-  grid.layout(nrow(layout), ncol(layout))
    pushViewport(viewport(layout = la))
    ## Make each plot, in the correct location
    for (i in numPlots:1) {
      ## Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))
      vp = viewport(layout.pos.row = matchidx$row, layout.pos.col = matchidx$col)
      
      ## textplot: correlation coefficient
      if(matchidx$row < matchidx$col){
        numb = plots[[i]]
        col='black'
        ## dynamic font size for correlations
        ##size = min(max(abs(90*as.numeric(numb)), 25), 50)
        size = min(max(abs(90*as.numeric(numb)), 25), 40)
        grid.rect(width=unit(.85, 'npc'), height=unit(.85, 'npc'), vp=vp, gp=gpar(fill='grey95', col='transparent'))
        grid.text(numb, vp=vp, gp=gpar(fontsize=size, col=col))
      } else {
        print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                        layout.pos.col = matchidx$col))
      }
    }
  } ## end function 'multiplot'
  #########################################################################
  ##
  ##                     do the actual plotting
  ##
  #########################################################################
  
  ## list to store the plots
  plotList=vector('list', N*N)
  count=1
  for(i in 1:N)
    for(j in 1:N){
      
      ## extract pairwise data
      dat <- data.frame(x=mat[,colnames(mat)[i]], y=mat[,colnames(mat)[j]])
      #dat <- data.frame(x=mat[,i], y=mat[,j])
      rownames(dat) <- rownames(mat)
      
      ## filter according to xlim/ylim
      dat$x[ which(dat$x < lim[1] | dat$x > lim[2]) ] <- NA
      dat$y[ which(dat$y < lim[1] | dat$y > lim[2]) ] <- NA
      
      ## extract groups
      current.group <- unique(grp[names(grp)[c(i,j)]])
  
      ###########################
      ## lower triangle
      if(i < j){
        
        ## hexbin
        ##hex <- hexbin(dat$x, dat$y, hexbin, xbnds=range(dat$x, na.rm=T), ybnds=range(dat$y, na.rm=T) )
        hex <- hexbin(dat$x, dat$y, hexbin, xbnds=lim, ybnds=lim )
        gghex <- data.frame(hcell2xy(hex), c = cut2(hex@count, g = hexcut))
        p <- ggplot(gghex) + geom_hex(aes(x = x, y = y, fill = c) ,stat = "identity") + guides(fill=FALSE) + theme( plot.margin=unit(rep(0, 4), 'cm')) + xlab('') + ylab('') + xlim(lim[1], lim[2]) + ylim(lim[1], lim[2])
        
        ##if(length(current.group) == 1)
        ##    p <- p + scale_fill_manual( values=paste(rep( grp.col.legend[current.group], hexcut) ))
        ##else
        
        p <- p + scale_fill_manual( values=paste('grey', ceiling(seq(70, 20, length.out=hexcut)), sep=''))
        
        
        ## add filtered values
        if(!is.null(repro.filt) & length(current.group) == 1){
          not.valid.idx <- repro.filt[[current.group]]
          dat.repro <- dat[not.valid.idx, ]
          ##cat(not.valid.idx)
          ##cat(dim(dat.repro))
          p = p + geom_point( aes(x=x, y=y ), data=dat.repro, colour=my.col2rgb('blue', 50), size=1)
        }
      }
      ###########################
      ## diagonal
      if(i == j){
        p = ggplot(dat, aes(x=x)) + geom_histogram(fill=grp.col.legend[current.group], colour=grp.col.legend[current.group], binwidth=sum(abs(range(dat$x, na.rm=T)))/50) + ggtitle(colnames(mat)[i]) + theme(plot.title=element_text(size=9)) + theme( panel.background = element_blank(), plot.margin=unit(rep(0, 4), 'cm')) + xlab(paste('N',sum(!is.na(dat$x)), sep='=')) + ylab('') + xlim(lim[1], lim[2]) ##+ annotate('text', label=sum(!is.na(dat$x)), x=unit(0, 'npc'), y=unit(0, 'npc'))
        
        
      }
      ###########################
      ## upper triangle
      if(i > j){
        #cortmp = cm[i, j]
        cortmp = cm[j, i] # had to swap this since I am calcualting the correlation matrix separately
                          # otherwise the numbers in the multiscatters would be a mix of pearson/spearman
                          # coefficients (but no sample mix-up) 
        
        p=paste(round(cortmp, 3))
        
      }
      
      plotList[[count]] <- p
      count=count+1
    }
  
  multiplot( plotList, cols=N)
}

#####################################################
## visualize variances explained by PCA
##
## pca - pca object calculated by function PCA
##
#####################################################
plotPCAvar <- function(pca, pch=22, cex=2, lwd=2, ...){
  
  col1='darkblue'
  col2='red'
  
  ## extract the variances
  pca.var.perc = pca$var/pca$totalvar*100
  pca.var.cum = cumsum(pca$var)/pca$totalvar*100
  
  ## plot
  plot( pca.var.perc, type='b', pch=pch, col=col1, cex=cex, ylab='Percent variance', ylim=c(0,100),xlab='Principle Components', xaxt='n', ...)
  axis(1, at=1:ncol(pca$scores))
  lines(pca.var.cum, lwd=lwd, pch=pch+1, cex=cex, col=col2, type='b')
  legend('right', legend=c('Indiv. Var.', 'Cumulative Var,'), pch=c(pch, pch+1), lwd=lwd, col=c(col1, col2), bty='n', cex=1.3 )
}


##########################################################################################################
##                     translate a color name into rgb space
##
## changelog:  20100929 implementation
##########################################################################################################
my.col2rgb <- function(color, alpha=80, maxColorValue=255){
  
  out <- vector( "character", length(color) )
  
  for(col in 1:length(color)){
    
    col.rgb <- col2rgb(color[col])
    
    out[col] <- rgb(col.rgb[1], col.rgb[2], col.rgb[3], alpha=alpha, maxColorValue=maxColorValue)
    
  }
  return(out)
}

#####################################################
## color ramp
##
####################################################
myColorRamp <- function(colors, values, opac=1, range=NULL) {
  
  if(is.null(range))
    v <- (values - min(values))/diff(range(values))
  else
    v <- (values - min(values, na.rm=T))/diff( range )
  
  x <- colorRamp(colors)(v)

  rgb(x[,1], x[,2], x[,3], alpha=opac*255, maxColorValue = 255)
}
