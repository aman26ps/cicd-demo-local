FROM nginx:alpine

# Copy custom HTML content
COPY src/index.html /usr/share/nginx/html/index.html
COPY src/nginx.conf /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
