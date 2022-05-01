--Covid-19 Data Exploration with SQL
--The data is updated until 18/04/2022

SELECT *
FROM SQLPractice_Covid19..CovidDeaths
order by 1,2

SELECT *
FROM SQLPractice_Covid19..CovidVaccination


--Select Data that I am going to use

Select Location, date, total_cases, new_cases,total_deaths, population
From SQLPractice_Covid19..CovidDeaths
order by 1,2

--The total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your country
--Cast the columns in the float to calculate (original :nvarchar)

Select Location, date, total_cases, total_deaths,(CAST(total_deaths AS float)/CAST(total_cases AS float))*100 as DeathPercentage
FROM SQLPractice_Covid19..CovidDeaths
WHERE location like '%state%' 
order by 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, population, total_cases, (CAST(total_cases AS float)/CAST(population AS float))*100 as PercentPopulationInfected
FROM SQLPractice_Covid19..CovidDeaths
WHERE location like '%state%'
order by 1,2

-- Countries with Highest Infection Rate compared to Population
--Msg 8134, Level 16, State 1, Line 32
--Divide by zero error encountered.

Select Location, population, MAX(total_cases )AS HighestInfectionCount, MAX((CAST(total_cases AS float)/CAST(population AS float))*100)as PercentPopulationInfected
FROM SQLPractice_Covid19..CovidDeaths
Where population is not null
Group by Location, population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(total_deaths as float) )AS TotalDeathCount
FROM SQLPractice_Covid19..CovidDeaths
Where continent is not null 
Group by Location
order by TotalDeathCount desc

-- BREAKING DOWN BY CONTINENT
-- Showing contintents with the highest death count per population

Select continent, MAX(cast(total_deaths as float) )AS TotalDeathCount
FROM SQLPractice_Covid19..CovidDeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc


-- GLOBAL NUMBERS

Select date, sum(cast(new_cases as float)) as NewCases, sum(cast(total_cases as float)) as TotalCases,sum(cast(new_deaths as float)) as NewDeaths, sum(cast(total_deaths as float))as TotalDeaths
From SQLPractice_Covid19..CovidDeaths
where continent is not null 
Group by date
order by date asc



--Explore the relation between two tables, deaths and vaccination


Select *
From SQLPractice_Covid19..CovidVaccination

Select *
From SQLPractice_Covid19..CovidDeaths dea
Join SQLPractice_Covid19..CovidVaccination vac
on dea.location = vac.location
and dea.date = vac.date

-- Total Population vs Vaccinations

Select dea.continent, dea.location,dea.date,dea.population,vac.people_vaccinated
From SQLPractice_Covid19..CovidDeaths dea
Join SQLPractice_Covid19..CovidVaccination vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 1,2,3 


-- Shows Percentage of Population that has recieved at least one Covid Vaccine
-- Using partition function, and convert funtion instead of cast , Using CTE 

Select dea.continent, dea.location,dea.date, dea.population,vac.new_vaccinations,
sum(convert(float,vac.new_vaccinations)) over (Partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
From SQLPractice_Covid19..CovidDeaths dea
Join SQLPractice_Covid19..CovidVaccination vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 1,2,3 

-- CTE part

With PopvsVac(Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location,dea.date, dea.population,vac.new_vaccinations,
sum(convert(float,vac.new_vaccinations)) over (Partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
From SQLPractice_Covid19..CovidDeaths dea
Join SQLPractice_Covid19..CovidVaccination vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
)
Select *,(RollingPeopleVaccinated/Population)*100 as RollingPeopleVaccinatedPercentage
from PopvsVac



-- Shows Percentage of Population that has recieved at least one Covid Vaccine (same question)
-- Using partition function, and convert funtion instead of cast ,  Using "TEMP TABLE"
-- TEMP TABLE


DROP Table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location,dea.date, dea.population,vac.new_vaccinations,
sum(cast(vac.new_vaccinations as float)) over (Partition by dea.location order by dea.location,dea.date) 
as RollingPeopleVaccinated
From SQLPractice_Covid19..CovidDeaths dea
Join SQLPractice_Covid19..CovidVaccination vac
on dea.location = vac.location
and dea.date = vac.date
--where dea.continent is not null

Select *,(RollingPeopleVaccinated/Population)*100 as RollingPeopleVaccinatedPercentage
from #PercentPopulationVaccinated



-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinatedview AS
Select dea.continent, dea.location,dea.date, dea.population,vac.new_vaccinations,
sum(cast(vac.new_vaccinations as float)) over (Partition by dea.location order by dea.location,dea.date) 
as RollingPeopleVaccinated
From SQLPractice_Covid19..CovidDeaths dea
Join SQLPractice_Covid19..CovidVaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
