/*
COVID-19 Data Exploration 

Skills Highlighted: Joins, CTEs, Temp Tables, Windows Functions, Aggregate Functions, Creating Views
*/

SELECT * 
  FROM  dbo.CovidDeaths
  WHERE continent is not null 
  order by 3,4


-- Select starting data 

SELECT location, date, total_cases, new_cases, total_deaths, population
  FROM  dbo.CovidDeaths
  WHERE continent is not null 
  order by 1, 2


-- Looking at Total Cases vs Total Deaths in order to determine probability of dying from COVID-19 in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as probability_of_death
  FROM  dbo.CovidDeaths
  WHERE continent is not null 
  order by 1, 2


-- Examine Total Cases vs Population to show what percentage of a country's population was infected with COVID-19.

SELECT location, date, total_cases, population, (total_cases/population)*100 as percent_infected
  FROM  dbo.CovidDeaths
  WHERE location = 'United States' and continent is not null 
  order by 1, 2


-- Looking at countries with the highest infection rates

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as highest_infection_percentage
  FROM  dbo.CovidDeaths
  WHERE continent is not null 
  group by location, population
  order by highest_infection_percentage desc


-- Show the countries with the highest death counts per population

SELECT location, MAX(total_deaths) as total_death_count
  FROM  dbo.CovidDeaths
  WHERE continent is not null 
  group by location
  order by total_death_count desc


-- Show the continents with the highest death counts per population

SELECT location, MAX(total_deaths) as total_death_count
  FROM  dbo.CovidDeaths
  WHERE continent is null 
  group by location
  order by total_death_count desc


-- Show the global probability of death by removing "location", and grouping by "date" instead

SELECT date, sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, 
(sum(new_deaths)/sum(new_cases))*100 as global_probability_of_death
  FROM  dbo.CovidDeaths
  WHERE continent is not null 
  group by date
  order by 1, 2


-- Join Covid Deaths table with Covid Vaccinations table

SELECT *
  FROM dbo.CovidDeaths as deaths
  JOIN dbo.CovidVaccinations as vaccs
      On deaths.location = vaccs.location
      and deaths.date = vaccs.date


-- Look at the rolling count total population vs total vaccinations

SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccs.new_vaccinations, 
(sum(vaccs.new_vaccinations) OVER (PARTITION BY deaths.location Order by deaths.location, deaths.date)) as vaccinated_rolling_count
  FROM dbo.CovidDeaths as deaths
  JOIN dbo.CovidVaccinations as vaccs
      On deaths.location = vaccs.location
      and deaths.date = vaccs.date
  WHERE deaths.continent is not null
  order by 2,3


-- Using a CTE to perform calculation on the partition we just created in the previous query
-- Compare the rolling count of vaccinated people vs total population, express as a percenter. 

WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, vaccinated_rolling_count)
as
(
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccs.new_vaccinations, 
(sum(vaccs.new_vaccinations) OVER (PARTITION BY deaths.location Order by deaths.location, deaths.date)) as vaccinated_rolling_count 
  FROM dbo.CovidDeaths as deaths
  JOIN dbo.CovidVaccinations as vaccs
      On deaths.location = vaccs.location
      and deaths.date = vaccs.date
  WHERE deaths.continent is not null
)
SELECT *, (vaccinated_rolling_count/population)*100 as percent_vaccinated_rolling_count
FROM PopvsVac


-- Create a temp table to perform calculations on previous partition
-- Demonstrates the use of temp tables

DROP TABLE IF EXISTS #PPV; -- Used to drop previous table if running this same query multiple times
CREATE TABLE #PPV
(
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Vaccinated_rolling_count numeric
)

INSERT INTO #PPV (Continent, Location, Date, Population, New_vaccinations, Vaccinated_rolling_count)
(
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccs.new_vaccinations, 
(sum(vaccs.new_vaccinations) OVER (PARTITION BY deaths.location Order by deaths.location, deaths.date)) as Vaccinated_rolling_count 
  FROM dbo.CovidDeaths as deaths
  JOIN dbo.CovidVaccinations as vaccs
      On deaths.location = vaccs.location
      and deaths.date = vaccs.date
  --WHERE deaths.continent is not null
)

SELECT *, (vaccinated_rolling_count/population)*100 as percent_vaccinated_rolling_count
FROM #PPV
WHERE Location = 'United States' -- Use this to narrow down data for US and check the math for accuracy. 
Order by 1, 2, 3



-- Creating View to store data for use in Tableau viz

Create View PercentPopulationVaccinated as
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccs.new_vaccinations, 
(sum(vaccs.new_vaccinations) OVER (PARTITION BY deaths.location Order by deaths.location, deaths.date)) as vaccinated_rolling_count 
  FROM dbo.CovidDeaths as deaths
  JOIN dbo.CovidVaccinations as vaccs
      On deaths.location = vaccs.location
      and deaths.date = vaccs.date
  WHERE deaths.continent is not null
