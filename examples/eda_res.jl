display(res)

# Start: 2025-01-07T00:00:00
# End: 2025-01-07T23:00:00
# Resolution: 60 minutes

# PowerSimulations Problem Auxiliary variables Results
# ┌─────────────────────────────────────────────┐
# │ StorageEnergyOutput__EnergyReservoirStorage │
# │ TimeDurationOn__ThermalStandard             │
# │ TimeDurationOff__ThermalStandard            │
# └─────────────────────────────────────────────┘

# PowerSimulations Problem Expressions Results
# ┌─────────────────────────────────────────────┐
# │ ProductionCostExpression__RenewableDispatch │
# │ ProductionCostExpression__ThermalStandard   │
# │ ActivePowerBalance__ACBus                   │
# └─────────────────────────────────────────────┘

# PowerSimulations Problem Parameters Results
# ┌──────────────────────────────────────────────────────┐
# │ ActivePowerTimeSeriesParameter__RenewableNonDispatch │
# │ ActivePowerTimeSeriesParameter__PowerLoad            │
# │ ActivePowerTimeSeriesParameter__RenewableDispatch    │
# └──────────────────────────────────────────────────────┘

# PowerSimulations Problem Variables Results
# ┌───────────────────────────────────────────────────────┐
# │ StorageEnergyShortageVariable__EnergyReservoirStorage │
# │ ActivePowerVariable__ThermalStandard                  │
# │ FlowActivePowerVariable__Line                         │
# │ EnergyVariable__EnergyReservoirStorage                │
# │ OnVariable__ThermalStandard                           │
# │ SystemBalanceSlackDown__ACBus                         │
# │ StorageEnergySurplusVariable__EnergyReservoirStorage  │
# │ StartVariable__ThermalStandard                        │
# │ ReservationVariable__EnergyReservoirStorage           │
# │ SystemBalanceSlackUp__ACBus                           │
# │ ActivePowerInVariable__EnergyReservoirStorage         │
# │ ActivePowerVariable__RenewableDispatch                │
# │ StopVariable__ThermalStandard                         │
# │ ActivePowerOutVariable__EnergyReservoirStorage        │
# └───────────────────────────────────────────────────────┘

# Use:
# read_aux_variable: PowerSimulations Problem Auxiliary variables Results
# read_expression: PowerSimulations Problem Expressions Results
# read_dual: PowerSimulations Problem Duals Results
# read_parameter: PowerSimulations Problem Parameters Results
# read_variable: PowerSimulations Problem Variables Results

# NOTE:

sort_res_cols(read_aux_variable(res, "TimeDurationOn__ThermalStandard"))
sort_res_cols(read_aux_variable(res, "TimeDurationOff__ThermalStandard"))
sort_res_cols(read_aux_variable(res, "StorageEnergyOutput__EnergyReservoirStorage"))

sort_res_cols(read_expression(res, "ProductionCostExpression__RenewableDispatch"))
sort_res_cols(read_expression(res, "ProductionCostExpression__ThermalStandard"))
sort_res_cols(read_expression(res, "ActivePowerBalance__ACBus"))

sort_res_cols(read_parameter(res, "ActivePowerTimeSeriesParameter__RenewableNonDispatch"))
sort_res_cols(read_parameter(res, "ActivePowerTimeSeriesParameter__PowerLoad"))
sort_res_cols(read_parameter(res, "ActivePowerTimeSeriesParameter__RenewableDispatch"))

sort_res_cols(read_variable(res, "StorageEnergyShortageVariable__EnergyReservoirStorage"))
sort_res_cols(read_variable(res, "ActivePowerVariable__ThermalStandard"))
sort_res_cols(read_variable(res, "FlowActivePowerVariable__Line"))
sort_res_cols(read_variable(res, "EnergyVariable__EnergyReservoirStorage"))
sort_res_cols(read_variable(res, "OnVariable__ThermalStandard"))
sort_res_cols(read_variable(res, "SystemBalanceSlackDown__ACBus"))
sort_res_cols(read_variable(res, "StorageEnergySurplusVariable__EnergyReservoirStorage"))
sort_res_cols(read_variable(res, "StartVariable__ThermalStandard"))
sort_res_cols(read_variable(res, "ReservationVariable__EnergyReservoirStorage"))
sort_res_cols(read_variable(res, "SystemBalanceSlackUp__ACBus"))
sort_res_cols(read_variable(res, "ActivePowerInVariable__EnergyReservoirStorage"))
sort_res_cols(read_variable(res, "ActivePowerVariable__RenewableDispatch"))
sort_res_cols(read_variable(res, "StopVariable__ThermalStandard"))
sort_res_cols(read_variable(res, "ActivePowerOutVariable__EnergyReservoirStorage"))
