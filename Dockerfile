# Build
FROM rust:latest as build

WORKDIR /usr/src/clean-hotel-backend

COPY . .

RUN cargo install diesel_cli --no-default-features --features sqlite
RUN ["cargo", "build", "--release"]
RUN ["diesel", "migration", "run"]

# Run
FROM ubuntu:latest

COPY --from=build /usr/src/clean-hotel-backend/target/release/clean-hotel-backend /usr/local/bin/clean-hotel-backend

#RUN ["sh", "-c", "echo \"deb http://security.ubuntu.com/ubuntu focal-security main\" >> /etc/apt/sources.list.d/focal-security.list"]
RUN ["sh", "-c", "echo \"deb http://security.ubuntu.com/ubuntu focal-security main\" >> /etc/apt/sources.list.d/focal-security.list"]
RUN ["apt-get", "update"]
RUN ["apt-get", "upgrade"]
RUN ["apt-get", "-y", "install", "sqlite3", "libsqlite3-dev", "libssl1.1", "libpq5"]

ARG API_PORT
ARG DATABASE_URL
ARG JWT_SECRET
ARG DB_CONNECTION_URL

ENV API_PORT=${API_PORT}
ENV DATABASE_URL=${DATABASE_URL}
ENV JWT_SECRET=${JWT_SECRET}
ENV DB_CONNECTION_URL=${DB_CONNECTION_URL}

EXPOSE ${API_PORT}

CMD ["/usr/local/bin/clean-hotel-backend"]
