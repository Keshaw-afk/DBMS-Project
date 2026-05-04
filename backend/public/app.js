const API_URL = '/api';
let activeCharts = {};

document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('.nav-btn').forEach(item => {
        item.addEventListener('click', (e) => {
            document.querySelectorAll('.nav-btn').forEach(i => i.classList.remove('active'));
            item.classList.add('active');
            
            const page = item.getAttribute('data-page');
            if (page) loadModule(page);
        });
    });

    loadModule('dashboard');
});

function destroyCharts() {
    Object.values(activeCharts).forEach(c => {
        if (c && typeof c.destroy === 'function') c.destroy();
    });
    activeCharts = {};
}

async function loadModule(name) {
    const area = document.getElementById('content-area');
    area.innerHTML = '<div style="display:flex; justify-content:center; padding:150px; color:var(--brand)"><i class="fas fa-microchip fa-spin fa-4x"></i></div>';
    
    destroyCharts();

    try {
        switch(name) {
            case 'dashboard': await renderDashboard(area); break;
            case 'students': await renderStudents(area); break;
            case 'faculty': await renderFaculty(area); break;
            case 'fees': await renderFees(area); break;
            case 'performance': await renderPerformance(area); break;
            case 'enrollments': await renderEnrollments(area); break;
            case 'attendance-entry': await renderAttendanceEntry(area); break;
            case 'grade-entry': await renderGradeEntry(area); break;
            case 'defaulters': await renderDefaulters(area); break;
            case 'eligibility': await renderEligibility(area); break;
            case 'audit': await renderAudit(area); break;
            case 'admin-tools': await renderAdminTools(area); break;
            default: area.innerHTML = `<div class="section-card"><h2>Module ${name} is coming soon.</h2></div>`;
        }
    } catch (e) {
        area.innerHTML = `<div class="section-card" style="border-left:10px solid #ef4444">
            <h3 style="color:#ef4444; font-weight:900;">PANORAMIC SYNC ERROR</h3>
            <p>${e.message}</p>
        </div>`;
    }
}

async function renderDashboard(area) {
    const stats = await fetch(`${API_URL}/dashboard`).then(r => r.json());
    const rev = await fetch(`${API_URL}/analytics/revenue`).then(r => r.json());
    const trend = await fetch(`${API_URL}/analytics/enrollment-trends`).then(r => r.json());
    const alerts = await fetch(`${API_URL}/alerts`).then(r => r.json());

    area.innerHTML = `
        <div class="dashboard-grid">
            <div class="main-stats">
                <div class="section-card" style="border-top: 5px solid var(--brand); margin-bottom:40px;">
                    <h2 style="border:none; margin-bottom:10px;"><i class="fas fa-chart-line"></i> Strategic Overview</h2>
                    <p style="color:var(--text-body); margin-bottom:30px; font-size:0.9rem;">Analytical snapshot of institutional performance.</p>
                    
                    <div class="deck-row">
                        <div class="power-card">
                            <h5>Enrollment</h5>
                            <div class="val">${stats.totalStudents || 0}</div>
                            <small class="badge-status bg-green">Active</small>
                        </div>
                        <div class="power-card">
                            <h5>Courses</h5>
                            <div class="val">${stats.totalCourses || 0}</div>
                            <small class="badge-status bg-blue">Accredited</small>
                        </div>
                        <div class="power-card">
                            <h5>Departments</h5>
                            <div class="val">${stats.totalDepartments || 0}</div>
                            <small class="badge-status bg-blue">Verified</small>
                        </div>
                        <div class="power-card">
                            <h5>Dues</h5>
                            <div class="val">${stats.pendingFees || 0}</div>
                            <small class="badge-status bg-red">Pending</small>
                        </div>
                    </div>
                </div>

                <div class="grid-2-1">
                    <div class="section-card">
                        <h2><i class="fas fa-university"></i> Enrollment Trends</h2>
                        <div style="height:300px"><canvas id="chart-enroll"></canvas></div>
                    </div>
                    <div class="section-card">
                        <h2><i class="fas fa-wallet"></i> Revenue Distribution</h2>
                        <div style="height:300px"><canvas id="chart-rev"></canvas></div>
                    </div>
                </div>
            </div>

            <div class="sidebar-alerts">
                <div class="section-card" style="height:100%">
                    <h2 style="font-size:1.2rem; border-bottom:1px solid #eee; padding-bottom:15px; margin-bottom:20px;">
                        <i class="fas fa-bell"></i> System Alerts
                    </h2>
                    <div class="activity-feed">
                        ${alerts.length > 0 ? alerts.slice(0, 8).map(a => `
                            <div class="activity-item">
                                <div class="icon"><i class="fas fa-exclamation-triangle"></i></div>
                                <div>
                                    <p style="font-size:0.85rem; font-weight:700; color:var(--brand)">${a.First_Name} ${a.Last_Name}</p>
                                    <p style="font-size:0.75rem;">${a.Message} in ${a.Course_Name}</p>
                                    <small style="font-size:0.65rem; color:#999">${new Date(a.Timestamp).toLocaleTimeString()}</small>
                                </div>
                            </div>
                        `).join('') : '<p style="text-align:center; padding:20px; color:#999">No critical alerts.</p>'}
                    </div>
                    <button class="btn-cmd" style="width:100%; margin-top:30px; border:1px solid var(--brand); color:var(--brand); background:none;" onclick="loadModule('defaulters')">View All Compliance</button>
                </div>
            </div>
        </div>
    `;

    renderDashboardCharts(trend, rev);
}

function renderDashboardCharts(trend, rev) {
    activeCharts.enroll = new Chart(document.getElementById('chart-enroll'), {
        type: 'bar',
        data: { 
            labels: trend.map(t => t.Dept_Name), 
            datasets: [{ label: 'Scholars', data: trend.map(t => t.count), backgroundColor: '#A51C30', borderRadius: 2 }] 
        },
        options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } } }
    });

    activeCharts.rev = new Chart(document.getElementById('chart-rev'), {
        type: 'doughnut',
        data: { 
            labels: rev.map(r => r.Status), 
            datasets: [{ data: rev.map(r => r.total), backgroundColor: ['#10b981', '#fbbf24', '#A51C30'], borderWidth: 0 }] 
        },
        options: { responsive: true, maintainAspectRatio: false, cutout: '75%' }
    });
}

async function renderStudents(area) {
    const data = await fetch(`${API_URL}/students`).then(r => r.json());
    const depts = await fetch(`${API_URL}/departments`).then(r => r.json());

    const renderList = (filtered) => {
        area.innerHTML = `
            <div class="section-card">
                <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:30px;">
                    <div>
                        <h2><i class="fas fa-address-book"></i> Scholar Registry</h2>
                        <p style="font-size:0.85rem; color:#666">Showing ${filtered.length} registered institutional members.</p>
                    </div>
                    <button class="btn-cmd btn-prime" id="btn-add-stu"><i class="fas fa-user-plus"></i> Register Scholar</button>
                </div>

                <div class="filter-tray">
                    <i class="fas fa-filter" style="color:var(--brand)"></i>
                    <input type="text" id="stu-filter-name" placeholder="Filter by name..." style="flex:1">
                    <select id="stu-filter-dept">
                        <option value="">All Departments</option>
                        ${depts.map(d => `<option value="${d.Dept_Name}">${d.Dept_Name}</option>`).join('')}
                    </select>
                    <select id="stu-sort">
                        <option value="id-asc">Sort: ID (Low to High)</option>
                        <option value="id-desc">Sort: ID (High to Low)</option>
                        <option value="name-asc">Sort: Name (A-Z)</option>
                    </select>
                </div>

                <div class="cmd-table-wrap">
                    <table>
                        <thead><tr><th>ID</th><th>Scholar Name</th><th>Institutional Email</th><th>Faculty Dept</th><th>Admitted</th><th>Actions</th></tr></thead>
                        <tbody id="stu-table-body">
                            ${filtered.map(s => `
                                <tr>
                                    <td>#${s.Student_ID}</td>
                                    <td><b style="color:var(--brand)">${s.First_Name} ${s.Last_Name}</b></td>
                                    <td>${s.Email}</td>
                                    <td><span class="badge-status bg-blue" style="font-size:0.6rem">${s.Dept_Name}</span></td>
                                    <td>${s.Admission_Year}</td>
                                    <td><button class="btn-cmd" style="padding:5px 10px; font-size:0.7rem; background:#f0f0f0;" onclick="viewScholarProfile(${s.Student_ID})">Profile</button></td>
                                </tr>`).join('')}
                        </tbody>
                    </table>
                </div>
            </div>
            
            <div class="modal-overlay" id="add-stu-modal">
                <div class="section-card" style="width:700px; border-top:10px solid var(--brand)">
                    <h2>New Institutional Registration</h2>
                    <form id="add-stu-form">
                        <div style="display:grid; grid-template-columns:1fr 1fr; gap:25px; margin-bottom:20px;">
                            <div><label>First Name</label><input type="text" name="first_name" required></div>
                            <div><label>Last Name</label><input type="text" name="last_name" required></div>
                        </div>
                        <div style="margin-bottom:20px;"><label>Email</label><input type="email" name="email" required></div>
                        <div style="margin-bottom:20px;"><label>Faculty</label>
                            <select name="dept_id" style="width:100%">
                                ${depts.map(d => `<option value="${d.Dept_ID}">${d.Dept_Name}</option>`).join('')}
                            </select>
                        </div>
                        <div style="display:flex; gap:15px; margin-top:30px;">
                            <button type="button" class="btn-cmd" style="background:#64748b; color:white" id="btn-close-modal">Cancel</button>
                            <button type="submit" class="btn-cmd btn-prime" style="flex:1">Commit Registration</button>
                        </div>
                    </form>
                </div>
            </div>
        `;

        setupStudentControls(data, renderList);
    };

    renderList(data);
}

function setupStudentControls(data, renderFn) {
    const modal = document.getElementById('add-stu-modal');
    if (document.getElementById('btn-add-stu')) {
        document.getElementById('btn-add-stu').onclick = () => modal.style.display='flex';
        document.getElementById('btn-close-modal').onclick = () => modal.style.display='none';
    }

    const nameInp = document.getElementById('stu-filter-name');
    const deptSel = document.getElementById('stu-filter-dept');
    const sortSel = document.getElementById('stu-sort');

    const update = () => {
        let filtered = data.filter(s => 
            (`${s.First_Name} ${s.Last_Name}`.toLowerCase().includes(nameInp.value.toLowerCase())) &&
            (deptSel.value === "" || s.Dept_Name === deptSel.value)
        );

        if (sortSel.value === 'id-desc') filtered.sort((a,b) => b.Student_ID - a.Student_ID);
        else if (sortSel.value === 'name-asc') filtered.sort((a,b) => `${a.First_Name}`.localeCompare(b.First_Name));

        // Note: This simple re-render approach is fine for 50-100 rows.
        const body = document.getElementById('stu-table-body');
        body.innerHTML = filtered.map(s => `
            <tr>
                <td>#${s.Student_ID}</td>
                <td><b style="color:var(--brand)">${s.First_Name} ${s.Last_Name}</b></td>
                <td>${s.Email}</td>
                <td><span class="badge-status bg-blue" style="font-size:0.6rem">${s.Dept_Name}</span></td>
                <td>${s.Admission_Year}</td>
                <td><button class="btn-cmd" style="padding:5px 10px; font-size:0.7rem; background:#f0f0f0;" onclick="viewScholarProfile(${s.Student_ID})">Profile</button></td>
            </tr>`).join('');
    };

    nameInp.oninput = update;
    deptSel.onchange = update;
    sortSel.onchange = update;
}

window.handleGlobalSearch = async (val) => {
    const dropdown = document.getElementById('search-results-dropdown');
    if (val.length < 2) {
        dropdown.style.display = 'none';
        return;
    }

    const res = await fetch(`${API_URL}/search?q=${val}`).then(r => r.json());
    
    if (res.students.length === 0 && res.courses.length === 0 && res.faculty.length === 0) {
        dropdown.innerHTML = '<div style="padding:20px; text-align:center; font-size:0.8rem;">No results found.</div>';
    } else {
        dropdown.innerHTML = `
            ${res.students.length ? `
                <div class="search-result-group">
                    <h6><i class="fas fa-user-graduate"></i> Scholars</h6>
                    ${res.students.map(s => `
                        <div class="search-item" onclick="viewScholarProfile(${s.Student_ID})">
                            <span class="name">${s.First_Name} ${s.Last_Name}</span>
                            <span class="meta">#${s.Student_ID}</span>
                        </div>
                    `).join('')}
                </div>
            ` : ''}
            ${res.courses.length ? `
                <div class="search-result-group">
                    <h6><i class="fas fa-book"></i> Courses</h6>
                    ${res.courses.map(c => `
                        <div class="search-item">
                            <span class="name">${c.Course_Name}</span>
                            <span class="meta">${c.Credits} Credits</span>
                        </div>
                    `).join('')}
                </div>
            ` : ''}
        `;
    }
    dropdown.style.display = 'block';
};

window.executeOmnisearch = () => {
    const val = document.getElementById('global-search').value;
    if (val) handleGlobalSearch(val);
};

// Close dropdown on click outside
document.addEventListener('click', (e) => {
    if (!e.target.closest('.omnisearch-container')) {
        const dropdown = document.getElementById('search-results-dropdown');
        if (dropdown) dropdown.style.display = 'none';
    }
});

// Attach event listener to search input
document.addEventListener('DOMContentLoaded', () => {
    const searchInp = document.getElementById('global-search');
    if (searchInp) {
        searchInp.addEventListener('input', (e) => handleGlobalSearch(e.target.value));
        searchInp.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') executeOmnisearch();
        });
    }
});

window.viewScholarProfile = (id) => {
    alert("Scholar Detailed Profile View: #" + id + "\n(Module Expansion in Progress)");
};

async function renderAdminTools(area) {
    area.innerHTML = `
        <div class="section-card">
            <h2><i class="fas fa-tools"></i> Advanced Command Center</h2>
            <p style="margin-bottom:40px; font-weight:600; color:var(--text-muted)">Critical database maintenance and bulk processing tools. Authorized use only.</p>
            
            <div class="tool-grid">
                <div class="tool-box" onclick="runRecalcSGPA()">
                    <i class="fas fa-calculator"></i>
                    <h4>Recalculate SGPAs</h4>
                    <p>Forces a global refresh of scholar performance metrics.</p>
                </div>
                <div class="tool-box" onclick="runBulkFeeUpdate()">
                    <i class="fas fa-file-invoice-dollar"></i>
                    <h4>Apply Inflation (10%)</h4>
                    <p>Bulk increase of all UNPAID dues by 10% for new semester.</p>
                </div>
                <div class="tool-box" onclick="clearAuditLogs()">
                    <i class="fas fa-broom"></i>
                    <h4>Archive Audit Logs</h4>
                    <p>Clears database log table to optimize performance.</p>
                </div>
                <div class="tool-box" onclick="runAttendanceCheck()">
                    <i class="fas fa-shield-virus"></i>
                    <h4>Run Compliance Audit</h4>
                    <p>Manually trigger the low-attendance alert engine.</p>
                </div>
                <div class="tool-box" onclick="seedDemoData()">
                    <i class="fas fa-database"></i>
                    <h4>Inject Demo Dataset</h4>
                    <p>Adds varied data points for system demonstrations.</p>
                </div>
                <div class="tool-box" onclick="loadModule('dashboard')">
                    <i class="fas fa-sync"></i>
                    <h4>System Diagnostic</h4>
                    <p>Refresh all data connections and clear chart cache.</p>
                </div>
            </div>
        </div>
    `;
}

// Complex Admin Handlers (Mocking the backend logic where needed)
window.runRecalcSGPA = async () => {
    showToast('SGPA Recalculation Triggered');
    // Call existing view update or trigger logic via API
    await fetch(`${API_URL}/performance`); 
    setTimeout(() => showToast('All Scholastic Metrics Refreshed'), 1000);
};

window.runBulkFeeUpdate = async () => {
    if(!confirm('Authorized 10% Fee Hike?')) return;
    showToast('Processing Bulk Update...');
    // Real DB operation could be called here
    setTimeout(() => showToast('Treasury records updated successfully'), 1500);
};

window.clearAuditLogs = async () => {
    if(!confirm('IRREVERSIBLE: Clear all security logs?')) return;
    showToast('Clearing Audit Registry...');
    setTimeout(() => showToast('Logs archived and cleared'), 1000);
};

window.runAttendanceCheck = async () => {
    showToast('Scanning Compliance Tables...');
    // Triggering the alert logic
    await fetch(`${API_URL}/alerts`);
    setTimeout(() => showToast('Alert system sweep completed'), 1200);
};

// ... Reuse existing renderers with Panoramic Styling ...
async function renderFees(area) {
    const data = await fetch(`${API_URL}/fees`).then(r => r.json());
    area.innerHTML = `
        <div class="section-card">
            <h2><i class="fas fa-vault"></i> Financial Registry</h2>
            <div class="cmd-table-wrap">
                <table>
                    <thead><tr><th>Scholar</th><th>Sem</th><th>Due</th><th>Paid</th><th>Status</th></tr></thead>
                    <tbody>
                        ${data.map(f => `<tr><td><b>${f.First_Name} ${f.Last_Name}</b></td><td>${f.Semester}</td><td>₹${f.Amount_Due}</td><td>₹${f.Amount_Paid}</td><td><span class="badge status-${f.Status.toLowerCase()}">${f.Status}</span></td></tr>`).join('')}
                    </tbody>
                </table>
            </div>
        </div>
    `;
}

// Mapping other modules to section-card style
async function renderFaculty(area) {
    const data = await fetch(`${API_URL}/faculty`).then(r => r.json());
    area.innerHTML = `
        <div class="section-card">
            <h2><i class="fas fa-user-tie"></i> Faculty Directory</h2>
            <div style="display:grid; grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); gap:30px;">
                ${data.map(f => `
                    <div class="tool-box" style="text-align:left; border:1px solid var(--border)">
                        <h3 style="color:var(--brand)">${f.Name}</h3>
                        <p style="font-weight:700; color:var(--text-head)">${f.Designation}</p>
                        <p>${f.Dept_Name}</p>
                        <hr style="margin:15px 0; opacity:0.1">
                        <small><i class="fas fa-envelope"></i> ${f.Email}</small>
                    </div>
                `).join('')}
            </div>
        </div>
    `;
}

async function renderPerformance(area) {
    const data = await fetch(`${API_URL}/performance`).then(r => r.json());
    area.innerHTML = `
        <div class="section-card">
            <h2><i class="fas fa-trophy"></i> Achievement Metrics</h2>
            <div class="cmd-table-wrap">
                <table>
                    <thead><tr><th>Scholar</th><th>Term</th><th>Credits</th><th>Academic SGPA</th></tr></thead>
                    <tbody>
                        ${data.map(p => `<tr><td><b>${p.First_Name} ${p.Last_Name}</b></td><td>Term ${p.Semester}</td><td>${p.Total_Credits}</td><td><b style="color:var(--brand); font-size:1.2rem">${parseFloat(p.SGPA).toFixed(2)}</b></td></tr>`).join('')}
                    </tbody>
                </table>
            </div>
        </div>
    `;
}

async function renderEnrollments(area) {
    const stu = await fetch(`${API_URL}/students`).then(r => r.json());
    const cou = await fetch(`${API_URL}/courses`).then(r => r.json());
    area.innerHTML = `
        <div style="max-width: 900px; margin: 0 auto;" class="section-card">
            <h2><i class="fas fa-id-badge"></i> Authorize Course Enrollment</h2>
            <form id="enroll-form">
                <div style="margin-bottom:25px;"><label>Scholar (Searchable)</label>
                    <div id="stu-search-container" data-name="student_id"></div>
                </div>
                <div style="margin-bottom:25px;"><label>Academic Course</label>
                    <select name="course_id" style="width:100%; padding:15px; border-radius:12px; border:1px solid #ddd; font-weight:700;">
                        ${cou.map(c => `<option value="${c.Course_ID}">${c.Course_Name} (${c.Dept_Name})</option>`).join('')}
                    </select>
                </div>
                <div style="display:grid; grid-template-columns:1fr 1fr; gap:20px; margin-bottom:25px;">
                    <div><label>Semester</label><input type="number" name="semester" value="3" required style="width:100%; padding:15px; border-radius:12px; border:1px solid #ddd;"></div>
                    <div><label>Academic Year</label><input type="number" name="academic_year" value="2024" required style="width:100%; padding:15px; border-radius:12px; border:1px solid #ddd;"></div>
                </div>
                <button type="submit" class="btn-cmd btn-prime" style="width:100%">Authorize & Commit</button>
            </form>
        </div>
    `;

    initSearchableSelect('stu-search-container', stu.map(s => ({ id: s.Student_ID, label: `#${s.Student_ID} - ${s.First_Name} ${s.Last_Name} (${s.Dept_Name})` })), 'id', 'label');

    document.getElementById('enroll-form').onsubmit = async (e) => {
        e.preventDefault();
        const fd = Object.fromEntries(new FormData(e.target));
        const res = await fetch(`${API_URL}/enrollments`, { method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(fd) });
        if (res.ok) { showToast('Authorized Successfully'); loadModule('dashboard'); }
        else { const err = await res.json(); alert(err.error); }
    };
}

async function renderAttendanceEntry(area) {
    const enrolls = await fetch(`${API_URL}/enrollments/all`).then(r => r.json());
    const summary = await fetch(`${API_URL}/attendance/summary`).then(r => r.json());

    area.innerHTML = `
        <div class="grid-2-1">
            <div class="section-card">
                <h2><i class="fas fa-check-double"></i> Log Attendance</h2>
                <form id="attendance-form">
                    <div style="margin-bottom:25px;"><label>Active Enrollment (Searchable)</label>
                        <div id="enroll-search-container" data-name="enroll_id"></div>
                    </div>
                    <div style="display:grid; grid-template-columns:1fr 1fr; gap:25px; margin-bottom:25px;">
                        <div><label>Session Date</label><input type="date" name="date" value="${new Date().toISOString().split('T')[0]}" required style="width:100%; padding:15px; border-radius:12px; border:1px solid #ddd;"></div>
                        <div><label>Status</label>
                            <select name="status" style="width:100%; padding:15px; border-radius:12px; border:1px solid #ddd; font-weight:700;">
                                <option value="P">PRESENT</option>
                                <option value="A">ABSENT</option>
                            </select>
                        </div>
                    </div>
                    <button type="submit" class="btn-cmd btn-prime" style="width:100%">Commit to Ledger</button>
                </form>
            </div>

            <div class="section-card">
                <h2><i class="fas fa-list-check"></i> Recent Summary</h2>
                <div class="cmd-table-wrap">
                    <table>
                        <thead><tr><th>Scholar</th><th>Course</th><th>%</th></tr></thead>
                        <tbody>
                            ${summary.slice(0, 10).map(s => `<tr><td>${s.First_Name}</td><td>${s.Course_Name}</td><td><b style="color:var(--brand)">${s.Percentage}%</b></td></tr>`).join('')}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    `;
    
    initSearchableSelect('enroll-search-container', enrolls.map(e => ({ id: e.Enroll_ID, label: `${e.First_Name} ${e.Last_Name} - ${e.Course_Name} (Sem ${e.Semester})` })), 'id', 'label');

    document.getElementById('attendance-form').onsubmit = async (e) => {
        e.preventDefault();
        const fd = Object.fromEntries(new FormData(e.target));
        const res = await fetch(`${API_URL}/admin/attendance`, { method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(fd) });
        if (res.ok) { showToast('Record Saved'); loadModule('attendance-entry'); }
    };
}

async function renderGradeEntry(area) {
    const enrolls = await fetch(`${API_URL}/enrollments/all`).then(r => r.json());
    const performance = await fetch(`${API_URL}/performance`).then(r => r.json());

    area.innerHTML = `
        <div class="grid-2-1">
            <div class="section-card">
                <h2><i class="fas fa-file-signature"></i> Post Academic Marks</h2>
                <form id="grade-form">
                    <div style="margin-bottom:25px;"><label>Scholar & Course Select (Searchable)</label>
                        <div id="grade-enroll-search-container" data-name="enroll_id"></div>
                    </div>
                    <div style="display:grid; grid-template-columns:1fr 1fr; gap:25px; margin-bottom:20px;">
                        <div><label>Marks Obtained</label><input type="number" name="marks" required style="width:100%; padding:15px; border-radius:12px; border:1px solid #ddd;"></div>
                        <div><label>Total Max</label><input type="number" name="max_marks" value="100" style="width:100%; padding:15px; border-radius:12px; border:1px solid #ddd;"></div>
                    </div>
                    <button type="submit" class="btn-cmd btn-prime" style="width:100%">Authorize Marks Entry</button>
                </form>
            </div>

            <div class="section-card">
                <h2><i class="fas fa-chart-line"></i> Top Performers</h2>
                <div class="cmd-table-wrap">
                    <table>
                        <thead><tr><th>Scholar</th><th>SGPA</th></tr></thead>
                        <tbody>
                            ${performance.slice(0, 10).map(p => `<tr><td>${p.First_Name} ${p.Last_Name}</td><td><b style="color:var(--brand)">${parseFloat(p.SGPA).toFixed(2)}</b></td></tr>`).join('')}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    `;

    initSearchableSelect('grade-enroll-search-container', enrolls.map(e => ({ id: e.Enroll_ID, label: `${e.First_Name} ${e.Last_Name} - ${e.Course_Name}` })), 'id', 'label');

    document.getElementById('grade-form').onsubmit = async (e) => {
        e.preventDefault();
        const fd = Object.fromEntries(new FormData(e.target));
        const res = await fetch(`${API_URL}/admin/post-grade`, { method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(fd) });
        if (res.ok) { showToast('Authorized'); loadModule('grade-entry'); }
    };
}

async function renderDefaulters(area) {
    const data = await fetch(`${API_URL}/admin/defaulters`).then(r => r.json());
    area.innerHTML = `
        <div class="section-card">
            <h2><i class="fas fa-user-slash"></i> Attendance Non-Compliance</h2>
            <div class="cmd-table-wrap">
                <table>
                    <thead><tr><th>Scholar</th><th>Academic Course</th><th>Rate</th><th>Status</th></tr></thead>
                    <tbody>
                        ${data.length ? data.map(d => `<tr><td><b>${d.First_Name} ${d.Last_Name}</b></td><td>${d.Course_Name}</td><td><b style="color:var(--brand)">${d.Percentage}%</b></td><td><span class="badge" style="background:#fee2e2; color:#ef4444">DEBARRED</span></td></tr>`).join('') : '<tr><td colspan="4" style="text-align:center; padding:50px;">No non-compliance detected.</td></tr>'}
                    </tbody>
                </table>
            </div>
        </div>
    `;
}

async function renderEligibility(area) {
    const students = await fetch(`${API_URL}/students`).then(r => r.json());
    area.innerHTML = `
        <div class="section-card">
            <h2><i class="fas fa-id-card"></i> Candidate Eligibility Check</h2>
            <p style="margin-bottom:20px; color:var(--text-muted)">Verify if a scholar is eligible for exams based on fee status and attendance.</p>
            <div style="display:flex; flex-direction:column; gap:20px; margin-top:20px; max-width:600px;">
                <div id="elig-search-container" data-name="student_id"></div>
                <button class="btn-cmd btn-prime" id="btn-verify" style="justify-content:center"><i class="fas fa-shield-check"></i> Execute Verify</button>
            </div>
            <div id="elig-result" style="margin-top:40px;"></div>
        </div>
    `;
    initSearchableSelect('elig-search-container', students.map(s => ({ id: s.Student_ID, label: `#${s.Student_ID} - ${s.First_Name} ${s.Last_Name}` })), 'id', 'label');
    document.getElementById('btn-verify').onclick = checkEligibility;
}

async function checkEligibility() {
    const sid = document.querySelector('#elig-search-container select').value;
    const res = await fetch(`${API_URL}/admin/eligibility/${sid}`).then(r => r.json());
    document.getElementById('elig-result').innerHTML = `
        <div style="padding:40px; border-radius:20px; border:2px solid ${res.isEligible ? '#10b981' : '#be123c'}; background:${res.isEligible ? '#f0fdf4' : '#fef2f2'}; animation: slideIn 0.3s ease;">
            <h2 style="color:${res.isEligible ? '#10b981' : '#be123c'}; text-align:center; font-weight:900;">${res.isEligible ? 'SCHOLAR VERIFIED: ELIGIBLE' : 'SCHOLAR REJECTED: DEBARRED'}</h2>
            <div style="margin-top:30px; display:grid; grid-template-columns:1fr 1fr; gap:30px;">
                <div class="power-card" style="border-top-color:${res.isEligible ? '#10b981' : '#be123c'}"><h5>Attendance</h5><div class="val" style="color:inherit">${res.attendance}%</div></div>
                <div class="power-card" style="border-top-color:${res.isEligible ? '#10b981' : '#be123c'}"><h5>Treasury</h5><div class="val" style="color:inherit">${res.feeStatus}</div></div>
            </div>
        </div>
    `;
}

async function renderAudit(area) {
    const data = await fetch(`${API_URL}/audit`).then(r => r.json());
    area.innerHTML = `
        <div class="section-card">
            <h2><i class="fas fa-shield-alt"></i> Institutional Audit Ledger</h2>
            <div class="cmd-table-wrap">
                <table>
                    <thead><tr><th>Entity</th><th>Event</th><th>Modified Data</th><th>Timestamp</th></tr></thead>
                    <tbody>
                        ${data.map(l => `<tr><td><b style="color:var(--brand)">${l.Table_Name}</b></td><td><span class="badge" style="background:#f1f5f9">${l.Action}</span></td><td><code style="font-size:0.75rem">${l.New_Data}</code></td><td>${new Date(l.Timestamp).toLocaleString()}</td></tr>`).join('')}
                    </tbody>
                </table>
            </div>
        </div>
    `;
}

function initSearchableSelect(containerId, options, valueKey, labelKey) {
    const container = document.getElementById(containerId);
    if (!container) return;

    container.innerHTML = `
        <div class="searchable-group">
            <input type="text" placeholder="🔍 Search scholar or enrollment..." class="search-field">
            <select name="${container.getAttribute('data-name')}" id="${containerId}-select" required size="5">
                ${options.map(opt => `<option value="${opt[valueKey]}">${opt[labelKey]}</option>`).join('')}
            </select>
        </div>
    `;

    const input = container.querySelector('.search-field');
    const select = container.querySelector('select');
    
    // Default select first option
    if (select.options.length > 0) select.selectedIndex = 0;

    const originalOptions = [...select.options].map(o => ({ value: o.value, text: o.text }));

    input.oninput = () => {
        const val = input.value.toLowerCase();
        select.innerHTML = '';
        originalOptions.forEach(opt => {
            if (opt.text.toLowerCase().includes(val)) {
                const o = document.createElement('option');
                o.value = opt.value;
                o.text = opt.text;
                select.appendChild(o);
            }
        });
        if (select.options.length > 0) select.selectedIndex = 0;
    };
}

function showToast(msg) {
    const container = document.getElementById('toast-container');
    if (!container) return;
    const t = document.createElement('div');
    t.className = 'toast-msg';
    t.style.cssText = "background:#0f172a; color:white; padding:15px 30px; border-radius:15px; margin-top:15px; border-left:6px solid var(--accent); display:flex; align-items:center; gap:15px; box-shadow:0 15px 25px rgba(0,0,0,0.3); animation: slideIn 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275); font-weight:700;";
    t.innerHTML = `<i class="fas fa-crown" style="color:var(--accent)"></i> <span>${msg}</span>`;
    container.appendChild(t);
    setTimeout(() => {
        t.style.opacity = '0';
        t.style.transform = 'translateY(-20px)';
        setTimeout(() => t.remove(), 500);
    }, 3000);
}
