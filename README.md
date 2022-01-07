# OfficeMix

***OfficeMix*** is a computer tool based on Matlab, used to know the mix of electricity generation and demand in public buildings, and carry it out through computational calculation.

Its operation is based on a series of previously prepared functions, to which the necessary values must be entered for the start of the simulation by means of comma separated values (CSV) files.

## Files
***OfficeMix*** is made up of 5 CSV files and 4 Matlab code files. The most important one is the so-called `model.m`, since it will be the one that we must execute to start the simulation. The 9 files that make up the tool must be copied into our current folder, or Matlab's default directory.

![OfficeMix files in Matlab directory](https://user-images.githubusercontent.com/94860520/148534207-7cb3ee14-3083-485f-b228-e03ab7f74e69.png)


CSV files are the basis for entering almost all the data required for simulation. All of them can be edited from the Matlab directory itself. Just right click on one of them and select the option *Open Outside MATLAB*. Immediately the file in question will be opened from our spreadsheet processor program (Excel or similar).

Once we have made the corresponding changes, we must save the file again. In these cases, Excel usually indicates a warning message asking us if we want to continue using the CSV format. We choose the option *Yes* and close the file. If Excel asks us if we want to save the changes made to the file, we choose the option *Do not save*. This will save the changes made to each of the files. If we double click on a CSV from the Matlab directory, it will open a new window in which we can see if the changes made have been saved correctly.

![demand.csv file view from the Matlab window](https://user-images.githubusercontent.com/94860520/148534530-c7930aab-4032-44a3-bf1a-a36f3eb606af.png)


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
