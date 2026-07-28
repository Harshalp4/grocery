# --- Build stage ---
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Restore first (cached unless the csproj changes).
COPY *.csproj ./
RUN dotnet restore

# Build + publish.
COPY . ./
RUN dotnet publish -c Release -o /app --no-restore

# --- Runtime stage ---
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app ./
# Seed product images (served read-only at /uploads). New uploads written at
# runtime are ephemeral on Render — move to object storage for persistence.
COPY --from=build /src/uploads ./uploads

# Render/Railway inject PORT; the app binds to it. This is the local-docker default.
ENV ASPNETCORE_URLS=http://0.0.0.0:8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "FarmFresh.Api.dll"]
