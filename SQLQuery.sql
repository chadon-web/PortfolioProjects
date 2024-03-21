SELECT *
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 3,4

-- SELECT *
-- FROM CovidVaccinations
-- ORDER BY 3,4

--Select Data that we are going to use

SELECT [location],[date], total_cases, new_cases, total_cases, population
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 1,2

-- Looking at Total cases vs Total deaths
--Likelihood of dying by percentage for each country

SELECT 
    [location],
    [date], 
    total_cases, 
    total_deaths, 
    (total_deaths * 100.0 / total_cases) AS DeathPercentage
FROM 
   PortfolioProject.dbo.CovidDeaths
   WHERE [location] like '%united kingdom%'
ORDER BY 1,2

--Looking at total cases vs population
--Shows what percentage of population got covid

SELECT [location],[date], population, total_cases, (total_cases * 100.0 / population) AS PopulationInfectedPercentage
FROM PortfolioProject.dbo.CovidDeaths
   WHERE [location] like '%united kingdom%'
ORDER BY 1,2

--Looking at countries with highest infection rate compared to their population

SELECT [location], population, MAX(total_cases) as HigestInfectionCount, MAX((total_cases * 100.0 / population)) AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
GROUP BY [location], population
ORDER BY PercentPopulationInfected DESC

--Looking at countries with highest death rate per population

SELECT [location], continent, MAX(total_deaths) as HigestDeathCount, MAX((total_deaths * 100.0 / population)) AS PercentPopulationDeath
FROM PortfolioProject.dbo.CovidDeaths
Where continent is not NULL
GROUP BY [location], continent, population
ORDER BY HigestDeathCount DESC

-- Looking at continent with highest death rate per population

SELECT [location], MAX(total_deaths) as HigestDeathCount
FROM PortfolioProject.dbo.CovidDeaths
Where continent is NULL
GROUP BY [location]
ORDER BY HigestDeathCount DESC




SELECT SUM(CAST(new_cases AS BIGINT)) AS TotalSum
FROM PortfolioProject.dbo.CovidDeaths
WHERE [location] <> '%world%'
  --GROUP by [location]

-- Global total
SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(cast(new_deaths as float))*100/SUM(cast(new_cases as float)) as DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
where continent is not null
--GROUP BY date
ORDER BY 1,2

--Looking at total population vs vaccinations
--Joining death and vaciination tables
SELECT death.continent, death.[location], death.[date], death.population, vaccine.new_vaccinations
FROM PortfolioProject.dbo.CovidDeaths death
JOIN PortfolioProject.dbo.CovidVaccinations vaccine
ON death.[location] = vaccine.[location]
and death.[date] = vaccine.[date]
WHERE death.continent is not null
order by 2,3

-- Calcuating the rolling number of people as they are vaccinated
SELECT death.continent, death.[location], death.[date], death.population, vaccine.new_vaccinations,
SUM(vaccine.new_vaccinations) OVER (Partition by death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths death
JOIN PortfolioProject.dbo.CovidVaccinations vaccine
ON death.[location] = vaccine.[location]
and death.[date] = vaccine.[date]
WHERE death.continent is not null
order by 2,3

--Using CTE
-- To know the maximum people vaccinated in the country
With PopulationVsVaccination(continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT death.continent, death.[location], death.[date], death.population, vaccine.new_vaccinations,
SUM(vaccine.new_vaccinations) OVER (Partition by death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths death
JOIN PortfolioProject.dbo.CovidVaccinations vaccine
ON death.[location] = vaccine.[location]
and death.[date] = vaccine.[date]
WHERE death.continent is not null
--order by 2,3
)
SELECT * , (CONVERT (float,RollingPeopleVaccinated)/population)*100 --So that we do not get a zero result
FROM PopulationVsVaccination


--using TEMP Table
DROP TABLE if EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    continent NVARCHAR(255),
    location NVARCHAR(255),
    date DATETIME,
    population NUMERIC,
    new_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
)
INSERT into #PercentPopulationVaccinated
SELECT death.continent, death.[location], death.[date], death.population, vaccine.new_vaccinations,
SUM(vaccine.new_vaccinations) OVER (Partition by death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths death
JOIN PortfolioProject.dbo.CovidVaccinations vaccine
ON death.[location] = vaccine.[location]
and death.[date] = vaccine.[date]
--WHERE death.continent is not null
--order by 2,3
SELECT * , (CONVERT (float,RollingPeopleVaccinated)/population)*100 --So that we do not get a zero result
FROM #PercentPopulationVaccinated


--creating view to store data for later visulaizations

CREATE VIEW PercentPopulationVaccinated as 
SELECT death.continent, death.[location], death.[date], death.population, vaccine.new_vaccinations,
SUM(vaccine.new_vaccinations) OVER (Partition by death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths death
JOIN PortfolioProject.dbo.CovidVaccinations vaccine
ON death.[location] = vaccine.[location]
and death.[date] = vaccine.[date]
WHERE death.continent is not null
--order by 2,3

-- For highest death count
CREATE VIEW HigestDeathCount as
SELECT [location], MAX(total_deaths) as HigestDeathCount
FROM PortfolioProject.dbo.CovidDeaths
Where continent is NULL
GROUP BY [location]
--ORDER BY HigestDeathCount DESC