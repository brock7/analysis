for %%p in (*.luaobj) do java -jar unluac.jar %%p > %%~np.lua