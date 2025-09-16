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

read_variable(res, "ActivePowerOutVariable__EnergyReservoirStorage")

read_aux_variable(res, "TimeDurationOn__ThermalStandard")
read_aux_variable(res, "TimeDurationOff__ThermalStandard")
read_aux_variable(res, "StorageEnergyOutput__EnergyReservoirStorage")