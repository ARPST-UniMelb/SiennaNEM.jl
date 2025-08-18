using SiennaNEM

# Path to the directory containing CSV files
data_dir = "data/nem12"

# Read data from CSV files
data = read_data_csv(data_dir)

# Build the power system
create_system!(data)

# Print the system components
println("System components:")
println(data["components"])
