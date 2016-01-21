m = Map("qmp", translate("qMp system settings"), translate("Here you can configure the basic aspects of your qMp device, like its hostname, location, etc."))

sect = m:section(NamedSection, "node", "qmp", translate("Basic system settings"))
sect.anonymous = true
sect.addremove = false

-- General settings tab
sect:tab("general", translate("General settings"), translate("Fill in the fields below the details about the node. The chosen name will be used to identify your device in the mesh network, and to distinguish it from the other devices."))

-- Node name
gen_name = sect:taboption("general", Value, "node_id", translate("Node name:"), translate("This name will identify your device in the mesh network (e.g. \"SesameStreet123\")."))
gen_name.datatype = "hostname"
gen_name.default = "MyNode123"
gen_name.maxlength = 195
gen_name.optional = false
gen_name.rmempty = false

-- Community id
gen_comm = sect:taboption("general", Value, "community_id", translate("Community (optional):"), translate("A short tag that identifies your Community Network (e.g. \"MyCN\")."))
gen_comm.datatype = "hostname"
gen_comm.default = "CN"
gen_comm.maxlength = 45
gen_comm.optional = true
gen_comm.rmempty = false

-- Contact e-mail
gen_mail = sect:taboption("general", Value, "contact", translate("E-mail:"), translate("Your e-mail address, in case somebody in the mesh network needs to contact you."))
gen_mail.datatype = "string"
gen_mail.default = "admin@qmp.cat"
gen_mail.maxlength = 253
gen_mail.optional = false
gen_mail.rmempty = false



-- Location tab
sect:tab("location", translate("Location"), translate("Fill in the fields below the details about the device's position. This information is useful to generate links maps with external tools. "))

-- Node latitude
loc_lat = sect:taboption("location", Value, "latitude", translate("Latitude (°)"), translate ("The device's latitude geoposition (north/south) on the map (e.g. \"0.1234\")."))
loc_lat.datatype = "float"
loc_lat.default = 0.0

-- Node latitude
loc_lon = sect:taboption("location", Value, "longitude", translate("Longitude (°)"), translate ("The device's longitude geoposition (east/west) on the map (e.g. \"-9.8765\")."))
loc_lon.datatype = "float"
loc_lon.default = 0.0

-- Node latitude
loc_lon = sect:taboption("location", Value, "elevation", translate("Elevation (m)"), translate ("The device's elevation above the ground surface (e.g. \"10\")."))
loc_lon.datatype = "ufloat"
loc_lon.default = 5



return m