local health = vim.health or require "health"

local M = {}

M.check = function()
  health.start "Checking telescope-docker plugin..."

  -- Check if Docker binary is installed
  if vim.fn.executable "docker" == 1 then
    health.ok "Docker binary installed."
  else
    health.error "Docker binary not found. Please install Docker."
  end

  -- Check Docker version
  local version_output = vim.fn.systemlist "docker version --format '{{.Client.Version}}' 2>&1"
  if vim.v.shell_error == 0 then
    health.ok("Docker version: " .. table.concat(version_output, " "))
  else
    health.warn("Could not determine Docker version. Output: " .. table.concat(version_output, " "))
  end

  -- Check if Docker daemon is running by executing "docker info"
  local output = vim.fn.systemlist "docker info 2>&1"
  if vim.v.shell_error == 0 then
    health.ok "Docker daemon is running."
  else
    health.warn("Docker daemon might not be running. Output: " .. table.concat(output, " "))
  end

  -- Check if Telescope is installed
  if pcall(require, "telescope") then
    health.ok "Telescope is installed."
  else
    health.error "Telescope is not installed or not found."
  end

  -- Check if Plenary is installed
  if pcall(require, "plenary.job") then
    health.ok "Plenary is installed."
  else
    health.error "Plenary is not installed or not found."
  end
end

return M
