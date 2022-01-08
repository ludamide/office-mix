# OfficeMix

***OfficeMix*** is a computer tool based on Matlab, used to know the mix of electricity generation and demand in public buildings, and carry it out through computational calculation.

Its operation is based on a series of previously prepared functions, to which the necessary values must be entered for the start of the simulation by means of comma separated values (CSV) files.

## Files

***OfficeMix*** is made up of 5 CSV files and 4 Matlab code files. The most important one is the so-called `model.m`, since it will be the one that we must execute to start the simulation. The 9 files that make up the tool must be copied into our current folder, or Matlab's default directory.

![OfficeMix files in Matlab directory](https://user-images.githubusercontent.com/94860520/148534207-7cb3ee14-3083-485f-b228-e03ab7f74e69.png)


CSV files are the basis for entering almost all the data required for simulation. All of them can be edited from the Matlab directory itself. Just right click on one of them and select the option *Open Outside MATLAB*. Immediately the file in question will be opened from our spreadsheet processor program (Excel or similar).

Once we have made the corresponding changes, we must save the file again. In these cases, Excel usually indicates a warning message asking us if we want to continue using the CSV format. We choose the option *Yes* and close the file. If Excel asks us if we want to save the changes made to the file, we choose the option *Do not save*. This will save the changes made to each of the files. If we double click on a CSV from the Matlab directory, it will open a new window in which we can see if the changes made have been saved correctly.

Each CSV file has been prepared in advance so that the mathematical model can extract the data in the proper way. Next it will be explained how each of these files must be edited for the simulation to be carried out correctly.

### Convergence criteria

The `convergence.csv` file is the simplest file and therefore the easiest to edit. It consists of only two values.

The upper value indicates the maximum number of years allowed for the simulation. Its default value is *100* years.

The lower value represents the tolerance accepted by the model as valid to stop the simulation. In this model, that tolerance is indicated by the coefficient of variation of the *LOEE* index, and its default value is *0.004* (0.4%).

### Holidays

The `holiday.csv` file allows us to introduce the holidays with zero demand that we want to include in our simulation through a column vector. These holidays must be entered one below the other based on their numerical position in a non-leap year.

For example, Christmas Day is celebrated on December 25, which is the 359th day of a 365-day year. If we wanted to introduce that day as a holiday, we would indicate the value *359*.

### Battery data

The most important characteristics of the battery used should be entered in the `battery.csv` file. The values must be arranged in a column vector as indicated in the following table:

| ROW |    PARAMETER   |            UNIT            |
| :---: | :----------: | :------------------------: |
| 1 | Maximum charging power | W |
| 2 | Maximum discharge power | W |
| 3 | Maximum charge level | Wh |
| 4 | Minimum charge level | Wh |
| 5 | *MTTF* | Hours |
| 6 | *MTTR* | Hours |
| 7 | Installation cost | € |

### Building characteristics

The data concerning the internal layout of the analyzed building must be entered in the `demand.csv` file. This file is arranged as a table in which each row represents a different room in the building, and you can add as many rooms as you want.

Its layout is similar to this:

![demand.csv file view from the Matlab window](https://user-images.githubusercontent.com/94860520/148534530-c7930aab-4032-44a3-bf1a-a36f3eb606af.png)

The first value in the row represents the type of room in question. It can take a value of *0* if it is a meeting room, or *1* if it is an office room.

The second value will indicate the most important parameter for each room. In a meeting room, we shall indicate the **area of the room** in m<sup>2</sup>. In an office room, we shall indicate the **number of computers** present.

The third and last value shows the type of luminaire used in the room, according to the following model:
- Value *1* for **incandescent lamps**.
- Value *2* for **halogen lamps**.
- Value *3* for **LED or fluorescent lamps**.
- Value *4* for **metal-halide lamps**.
- Value *5* or *6* for **HIGH or LOW-pressure sodium lamps** respectively.
- Value *7* for **mercury-vapor lamps**.

### Generator system characteristics

The last editable file is `genConfig.csv`, where the most notable parameters of the generator systems used are exposed. It is a table in which each row represents a differentiated generator group.

The following table shows the values that must be entered in each column depending on the type of generator added:

|    COLUMN    |    1   |   2  |       3      |        4       |        5       |                6               |              7              |      8     |       9      |     10    |     11     |        12       |        13        |      14     |
|:------------:|:------:|:----:|:------------:|:--------------:|:--------------:|:------------------------------:|:---------------------------:|:----------:|:------------:|:---------:|:----------:|:---------------:|:----------------:|:-----------:|
| Wind Turbine | Status | Type | Units Number | *MTTF* [Hours] | *MTTR* [Hours] | Installation Cost per Unit [€] | Operating Cost per Unit [€] | *P<sub>nom</sub>* [W] | *v<sub>nom</sub>* [m/s] | *c* [m/s] |  *k* [m/s] | *v<sub>cut-in</sub>* [m/s] | *v<sub>cut-out</sub>* [m/s] |             |
|  Solar Panel | Status | Type | Units Number | *MTTF* [Hours] | *MTTR* [Hours] | Installation Cost per Unit [€] | Operating Cost per Unit [€] | *N<sub>OT</sub>* [ºC] |   *V<sub>OC</sub>* [V]  | *I<sub>SC</sub>* [A] | *V<sub>MPP</sub>* [V] |    *I<sub>MPP</sub>* [A]   |    *k<sub>I</sub>* [mA/K]   | *k<sub>V</sub>* [mV/K] |
|   Fuel Cell  | Status | Type | Units Number | *MTTF* [Hours] | *MTTR* [Hours] | Installation Cost per Unit [€] | Operating Cost per Unit [€] | *P<sub>nom</sub>* [W] |  *P<sub>min</sub>* [W]  |           |            |                 |                  |             |
|  Gas Turbine | Status | Type | Units Number | *MTTF* [Hours] | *MTTR* [Hours] | Installation Cost per Unit [€] | Operating Cost per Unit [€] | *P<sub>nom</sub>* [W] |  *P<sub>min</sub>* [W]  |           |            |                 |                  |             |
|     Other    | Status | Type | Units Number | *MTTF* [Hours] | *MTTR* [Hours] | Installation Cost per Unit [€] | Operating Cost per Unit [€] | *P<sub>nom</sub>* [W] |  *P<sub>min</sub>* [W]  |           |            |                 |                  |             |

In the **Status** section, it must be indicated whether that generator should be considered to carry out the simulation. It will take a value of *0* if it is inactive, or *1* if it is operational.

Under the **Type** section, we shall indicate the type of generating system in question:
- Value *1* for **wind turbines**.
- Value *2* for **solar panels**.
- Value *3* for **fuel cells**.
- Value *4* for **gas microturbines**.
- Value *5* for another type of **conventional generation** (e.g. diesel generators).

Depending on the type of generator added, a certain number of columns will be used, according to the arrangement of the previous table. Each row represents a certain distinct generation group, and you can add as many as you want.

![Typical genConfig.csv file view from the Matlab window](https://user-images.githubusercontent.com/94860520/148660303-a19248a4-741c-455f-a93b-b48716e935d6.png)

## Running the simulation

Once the CSV files have been correctly edited, we can start the simulation.

To do this, go to the Matlab current folder, look for the `modelo.m` file, right-click on it and select *Run* from the drop-down menu.

![Data entered via console](https://user-images.githubusercontent.com/94860520/148660665-7b8f6317-fa99-40b5-a3b8-6797bd1a46e9.png)

The model will request the introduction of two more necessary data, which must be entered through the Matlab command window.

First, we shall indicate the latitude of the location of our building, adding as many decimal places as desired. Values between -90º and 90º will be accepted (taking the Equator as 0º). In case of entering values outside this range, an error message will appear and a new acceptable value will be requested. Once entered, it is confirmed with the `Enter` key.

Next, you will be asked to indicate the occupancy profile of the building, which will take value *1* for morning hours (from 8:00 to 15:00) or value *2* for morning and afternoon split hours (from 8:00 to 13:00 and from 15:00 to 18:00). Values other than these will not be accepted. Otherwise, an error message will appear and a new acceptable value will be requested. Once entered, it is confirmed with the `Enter` key.

Once these data have been entered, the model will have all the necessary indications to be able to carry out the simulation correctly.

From this moment on, the Matlab command window will show the years of simulation carried out so far, as well as the tolerance achieved during that year.

![Command window view during simulation](https://user-images.githubusercontent.com/94860520/148661101-63d7908b-859a-49d2-b187-1e363a8112be.png)

Once the simulation is finished, the command window will indicate this by means of a message, and the `datos.mat` file will have been created in the directory, where the most important variables analyzed during the simulation will have been registered. These variables will be saved as tables, and can be easily plotted with Matlab's own PLOT tools, or exported for use in other programs.

![Some of the variables registered in datos.mat](https://user-images.githubusercontent.com/94860520/148661562-bff179c1-0114-4235-b873-15a5e4f38b17.png)

![Example of a graph made from Matlab itself](https://user-images.githubusercontent.com/94860520/148661396-4111b281-aad4-49ea-bfdc-5f0e14d96fbc.png)
