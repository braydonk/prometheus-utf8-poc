FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY . .
RUN go build -o main -ldflags="-s -w" .

FROM scratch
WORKDIR /app
COPY --from=builder /app/main .
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
EXPOSE 2223
CMD ["./main"]
