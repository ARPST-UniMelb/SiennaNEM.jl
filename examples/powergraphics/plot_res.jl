using PowerGraphics
using PowerAnalytics
plotlyjs()

gen = get_generation_data(res)
plot_powerdata(gen)
plot_fuel(res; generator_mapping_file="deps/generator_mapping.yml")
