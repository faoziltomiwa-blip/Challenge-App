var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

// Basic Root endpoint to just display any message confirming the API is running, along with environment info and timestamp
app.MapGet("/", () => new {
    Message = "API is running!",
    Environment = builder.Environment.EnvironmentName,
    Timestamp = DateTime.UtcNow
});

// Health check endpoint
app.MapGet("/health", () => Results.Ok(new { Status = "Healthy" }));

app.Run();