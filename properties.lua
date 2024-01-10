table.insert(props,{
  Name = 'Model',
  Type    = "enum", 
  Choices = {"VS series", "Other"},
  Value   = "Other"
})
table.insert(props,{
  Name = 'Input Count',
  Type = 'integer',
  Min = 2,
  Max = 127,
  Value = 4
})
table.insert(props,{
  Name = 'Output Count',
  Type = 'integer', 
  Min = 1,
  Max = 127,
  Value = 4
})
table.insert(props,{
  Name    = "Connection Type",
  Type    = "enum", 
  Choices = {"Ethernet", "Serial"},
  Value   = "Ethernet"
})
table.insert(props,{
  Name  = "Poll Interval",
  Type  = "integer",
  Min   = 1,
  Max   = 60, 
  Value = 10
})
table.insert(props,{
  Name  = "Get Device Info",
  Type  = "boolean",
  Value = true
})
table.insert(props,{
  Name    = "Debug Print",
  Type    = "enum",
  Choices = {"None", "Tx/Rx", "Tx", "Rx", "Function Calls", "All"},
  Value   = "None"
})
