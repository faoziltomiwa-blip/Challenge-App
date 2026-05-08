# Build Stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["ChallengeApp.csproj", "./"]
RUN dotnet restore "ChallengeApp.csproj"
COPY . .
RUN dotnet publish "ChallengeApp.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime Stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_HTTP_PORTS=8080

COPY --from=build /app/publish .
USER $APP_UID
ENTRYPOINT ["dotnet", "ChallengeApp.dll"]