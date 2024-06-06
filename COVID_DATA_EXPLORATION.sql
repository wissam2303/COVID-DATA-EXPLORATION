--COVID19 --data EXPLORATION--
--Skills used: Joins, CTE's, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

Select *, cast(date as varchar) as date
From coviddeath d
Where continent is not null 
order by 3,4

Select *, cast(date as varchar) as date
From vaccinations v 
Where continent is not null 
order by total_vaccinations 


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population, median_age 
From coviddeath d
Where continent is not null 
order by 1,2

Select continent,"location", "date" , total_cases, new_cases, total_deaths, population, median_age 
From coviddeath d
Where continent is not null 
order by 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select continent , location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From coviddeath d
--Where location like '%states%'
where continent is not null 
order by 2, 6


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date,  population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From coviddeath d
--Where location like '%states%'
order by  5 ;

-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From coviddeath d
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected 


-- Countries with Highest Death Count per Population

Select "location"  , MAX(Total_deaths) as TotalDeathCount
From coviddeath d 
--Where location like '%states%'
Where continent is not null
Group by "location" 
having MAX(Total_deaths) is not null
order by TotalDeathCount desc

-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population

Select continent, MAX(Total_deaths ) as TotalDeathCount
From coviddeath d
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc


--AGE/HDI/Total deaths/ Total cases

select * from coviddeath d;

select continent,location,date,population,total_cases, total_deaths, median_age, cardiovasc_death_rate, human_development_index
from coviddeath d
where continent is not null and total_cases is not null
order by location, total_cases desc 

-- GLOBAL NUMBERS

select location, date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths )/SUM(New_Cases)*100 as DeathPercentage
From coviddeath d
--Where location like '%states%'
where continent is not null and new_cases != 0
Group By location, date
order by 2, DeathPercentage



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(v.new_vaccinations) OVER (Partition by d.Location Order by d.location, d.date ) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From coviddeath d
full join vaccinations v 
	On d.location = v.location
	and d.date = cast( v."date" as varchar) 
where d.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

with cov_cte as 
(Select d.continent, d.location, d.population,d.total_cases, d.total_deaths, d.median_age,d.cardiovasc_death_rate, v.total_vaccinations,
SUM(v.new_vaccinations) OVER (Partition by d.Location Order by d.location, d.Date)  
From coviddeath d
full join vaccinations v 
	On d.location = v.location
	where d.continent is not null
order by 2,3
)
select*, (total_deaths / total_vaccinations) * 100 as dethvacratio
from cov_cte
where total_vaccinations != 0 and continent is not null;


With PopulationVac as
(Select d.continent, d.location, d.date, d.population, v.total_vaccinations, SUM(v.new_vaccinations) OVER (Partition by d.Location Order by d.location, d.date ) as RollingPeopleVaccinated
From coviddeath d
full join vaccinations v 
	On d.location = v.location
	and d.date = cast( v."date" as varchar) 
	where d.continent is not null
order by 2,3,6
)
Select *, (RollingPeopleVaccinated/Population)*100 as RollingPeopleVaccinatedpercentage
From PopulationVac;


with covid_cte as(
Select d.continent, d.location, d.date, d.population,d.total_cases,d.total_deaths, v.new_vaccinations, SUM(d.total_deaths) OVER (Partition by d.Location Order by d.location, d.date ) as Rollingdeathnumber
--, (RollingPeopleVaccinated/population)*100
From coviddeath d
full join vaccinations v 
	On d.location = v.location
	and d.date = cast( v."date" as varchar) 
where d.continent is not null 
order by 2,3)
select continent,location,population, sum(total_cases)as total_cases, sum(total_deaths)as total_deaths,(sum(total_deaths)/sum(total_cases))*100 as death_percentage,(new_vaccinations/population)*100 as vaccinationspercentage
from covid_cte
group by continent,location,population,new_vaccinations
order by location, total_cases;

-- Creating View to store data for later visualizations

Create View perpopulationvaccinated as
Select d.continent, d.location,d.date, d.population, v.total_vaccinations, SUM(v.new_vaccinations) OVER (Partition by d.Location Order by d.location, d.date) as RollingPeopleVaccinated
From coviddeath d
full join vaccinations v 
	On d.location = v.location
	and d.date = cast( v."date" as varchar) 
	where d.continent is not null
order by 2,3,6

Create View DeathVac as
Select d.continent, d.location, d.population,d.total_cases, d.total_deaths, d.median_age,d.cardiovasc_death_rate, v.total_vaccinations, SUM(v.new_vaccinations) OVER (Partition by d.Location Order by d.location, d.date) as RollingPeopleVaccinated
From coviddeath d
full join vaccinations v 
	On d.location = v.location
	where d.continent is not null
order by 2,3

Create view deaths_percentage as
with covid_cte as(
Select d.continent, d.location, d.date, d.population,d.total_cases,d.total_deaths, v.total_vaccinations, SUM(d.total_deaths) OVER (Partition by d.Location Order by d.location, d.date ) as Rollingdeathnumber
From coviddeath d
full join vaccinations v 
	On d.location = v.location
	and d.date = cast( v."date" as varchar) 
where d.continent is not null 
order by 2,3)
select continent,location,population, sum(total_cases)as total_cases, sum(total_deaths)as total_deaths,(sum(total_deaths)/sum(total_cases))*100 as death_percentage,(total_vaccinations/population)*100 as vaccinationspercentage
from covid_cte
group by continent,location,population,total_vaccinations
order by location, death_percentage;

create view medianageihd as 
select continent,location,date,population,total_cases, total_deaths, median_age, cardiovasc_death_rate, human_development_index
from coviddeath d
where continent is not null and total_cases is not null
order by location, total_cases desc 