# Dockerfile
FROM rocker/shiny:4.3.2

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libssl-dev \
    libcurl4-gnutls-dev \
    libxml2-dev \
    libgit2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('shiny', 'DBI', 'RPostgreSQL', 'DT', 'ggplot2', 'dplyr', 'shinydashboard', 'plotly'), repos='https://cran.rstudio.com/')"

# Copy application files
COPY app.R /srv/shiny-server/
COPY shiny-server.conf /etc/shiny-server/shiny-server.conf

# Make sure the directory is owned by shiny user
RUN chown -R shiny:shiny /srv/shiny-server

# Expose port
EXPOSE 3838

# Run shiny server
CMD ["/usr/bin/shiny-server"]