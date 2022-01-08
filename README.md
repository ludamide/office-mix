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

In the "Status" section, it must be indicated whether that generator should be considered to carry out the simulation. It will take a value of *0* if it is inactive, or *1* if it is operational.
