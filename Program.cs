var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

// Basic Root endpoint to display a message confirming the API is running, along with environment info and timestamp
app.MapGet("/", () => new {
    Message = "API is running via automated pipeline",
    Environment = builder.Environment.EnvironmentName,
    Timestamp = DateTime.UtcNow
});

// Health check endpoint
app.MapGet("/health", () => Results.Ok(new { Status = "Healthy" }));

app.Run();