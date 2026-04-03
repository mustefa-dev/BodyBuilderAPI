# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj and restore dependencies
COPY ["BodyBuilderAPI.csproj", "./"]
RUN dotnet restore "BodyBuilderAPI.csproj"

# Copy the rest of the code and build
COPY . .
RUN dotnet build "BodyBuilderAPI.csproj" -c Release -o /app/build

# Stage 2: Publish
FROM build AS publish
RUN dotnet publish "BodyBuilderAPI.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Stage 3: Runtime
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Expose the port Dokploy/Host expects
EXPOSE 8080

# Ensure the app listens on all network interfaces
ENV ASPNETCORE_URLS=http://+:8080

ENTRYPOINT ["dotnet", "BodyBuilderAPI.dll"]
