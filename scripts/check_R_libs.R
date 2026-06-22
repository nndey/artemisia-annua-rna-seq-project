packages <- c('DESeq2', 'clusterProfiler', 'tximport', 'ggplot2')
    
for (pkg in packages) {
    if (requireNamespace(pkg, quietly = TRUE)) {
        version <- as.character(packageVersion(pkg))
        cat(sprintf('%-20s %s\n', pkg, version))
    } else {
        cat(sprintf('%-20s NOT FOUND — check installation\n', pkg))
    }
}