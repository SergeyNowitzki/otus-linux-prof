# Use Nginx Alpine as base image
FROM redmine:latest

# In most cases, themes and plugins have git repositories where we can download the latest code.
RUN apt install -y git

# Clone git repo theme directly
RUN git clone https://github.com/farend/redmine_theme_farend_bleuclair.git public/themes/bleuclair
