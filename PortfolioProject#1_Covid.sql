--COVID 19 DATA EXPLORATION (24/2/2020 - 30/4/2021) (Done thanks to the instructions from AlexTheAnalyst)

--Skills used: Joins, CTE, Temp Tables, Window Functions, Aggregate Functions, Converting Data Types, Creating Views


SELECT *
FROM PortfolioProject..CovidDeaths$
--Where continent is not null
ORDER BY 3,4

SELECT location,date,population,total_cases,new_cases,total_deaths
FROM PortfolioProject..CovidDeaths$
Where continent is not null
ORDER BY 1,2

-- The likelihood of dying from Covid in Vietnam
SELECT location,date,population,total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths$
Where Location = 'Vietnam'
and continent is not null
ORDER BY 1,2

-- Looking at Total cases VS Population
-- Show what Percentage of Population got Covid in Vietnnam
SELECT location,date,population,total_cases,total_deaths, (total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
Where Location = 'Vietnam'
and continent is not null
ORDER BY 1,2

-- Looking at Countries with highest Infection Rate compared to Population
SELECT location,population,MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
Where continent is not null
GROUP BY location, population
ORDER BY PercentPopulationInfected desc

-- Continent with Highest Death Count (Note: where continent is null the location shows the aggregate data of the continent's covid data)
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths$
Where continent is null
and location not in ('World', 'European Union', 'International')
GROUP BY location
ORDER BY TotalDeathCount desc

-- Global total cases and total deaths

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
SUM(cast(New_deaths as int))/SUM(New_cases)*100 as DeathPercentage --total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths$
Where continent is not null
ORDER BY 1,2

-- Vaccination Percentage

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location,dea.date) AS PeopleVaccinated
FROM PortfolioProject..CovidDeaths$ as dea
JOIN PortfolioProject..CovidVaccinations$ as vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
ORDER BY 2,3

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (continent, location, date, population, New_vaccinations, PeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,dea.date) as PeopleVaccinated
FROM PortfolioProject..CovidDeaths$ as dea
JOIN PortfolioProject..CovidVaccinations$ as vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
)
SELECT *, (PeopleVaccinated/population)*100 AS PercentPopulationVaccinated
FROM PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE if exists #VaccinationPercentage
CREATE TABLE #VaccinationPercentage
(
Continent  nvarchar(255),
Location nvarchar (255),
Date datetime,
Population numeric,
New_vaccinations numeric,
PeopleVaccinated numeric
)
INSERT INTO #VaccinationPercentage
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths$ as dea
JOIN PortfolioProject..CovidVaccinations$ as vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
SELECT *, (PeopleVaccinated/population)*100 AS PercentPopulationVaccinated
FROM #VaccinationPercentage

---- Creating View to store data for later Visualization

CREATE VIEW Vaccination_Percentage AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,dea.date) AS PeopleVaccinated
FROM PortfolioProject..CovidDeaths$ AS dea
JOIN PortfolioProject..CovidVaccinations$ AS vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
