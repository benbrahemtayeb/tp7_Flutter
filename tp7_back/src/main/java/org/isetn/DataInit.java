package org.isetn;

import java.time.LocalDate;
import java.util.List;
import org.isetn.entities.Absence;
import org.isetn.entities.Classe;
import org.isetn.entities.Departement;
import org.isetn.entities.Etudiant;
import org.isetn.entities.Formation;
import org.isetn.entities.Matiere;
import org.isetn.entities.User;
import org.isetn.repository.AbsenceRepository;
import org.isetn.repository.ClasseRepository;
import org.isetn.repository.DepartementRepository;
import org.isetn.repository.EtudiantRepository;
import org.isetn.repository.FormationRepository;
import org.isetn.repository.MatiereRepository;
import org.isetn.repository.UserRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
public class DataInit implements CommandLineRunner {

    private final ClasseRepository classeRepository;
    private final FormationRepository formationRepository;
    private final UserRepository userRepository;
    private final DepartementRepository departementRepository;
    private final MatiereRepository matiereRepository;
    private final EtudiantRepository etudiantRepository;
    private final AbsenceRepository absenceRepository;

    public DataInit(ClasseRepository c, FormationRepository f, UserRepository u,
                    DepartementRepository d, MatiereRepository m,
                    EtudiantRepository e, AbsenceRepository a) {
        this.classeRepository = c;
        this.formationRepository = f;
        this.userRepository = u;
        this.departementRepository = d;
        this.matiereRepository = m;
        this.etudiantRepository = e;
        this.absenceRepository = a;
    }

    @Override
    public void run(String... args) {
        // Départements
        if (departementRepository.count() == 0) {
            departementRepository.save(new Departement(null, "TI"));
            departementRepository.save(new Departement(null, "GE"));
        }
        Departement ti = departementRepository.findAll().stream()
                .filter(d -> "TI".equals(d.getNomDept()))
                .findFirst()
                .orElseGet(() -> departementRepository.save(new Departement(null, "TI")));

        // Classes (les classes existantes sans département sont rattachées à TI)
        if (classeRepository.count() == 0) {
            classeRepository.save(new Classe(null, "DSI21", 0, ti));
            classeRepository.save(new Classe(null, "DSI22", 0, ti));
            classeRepository.save(new Classe(null, "DSI23", 0, ti));
        }
        for (Classe c : classeRepository.findAll()) {
            if (c.getDepartement() == null) {
                c.setDepartement(ti);
                classeRepository.save(c);
            }
        }

        if (formationRepository.count() == 0) {
            formationRepository.save(new Formation(null, "Developpement mobile", 40));
            formationRepository.save(new Formation(null, "Developpement web", 60));
        }
        if (userRepository.findByEmailAndPassword("admin@gmail.com", "admin") == null) {
            userRepository.save(new User(null, "admin@gmail.com", "admin"));
        }

        // Matières (S'assurer que toutes les matières Cours et TP sont sauvegardées)
        saveOrUpdateMatiere("AFCP", "AFCP (TP)", "Atelier framework cross-platform", "TP");
        saveOrUpdateMatiere("SOA", "SOA (Cours)", "Architecture orientee services", "COURS");
        saveOrUpdateMatiere("WEB_C", "WEB (Cours)", "Developpement web cours", "COURS");
        saveOrUpdateMatiere("WEB_TP", "WEB (TP)", "Developpement web TP", "TP");

        for (Matiere m : matiereRepository.findAll()) {
            if (m.getType() == null || m.getType().isEmpty()) {
                String name = (m.getCodMat() + " " + m.getIntMat() + " " + (m.getDescription() != null ? m.getDescription() : "")).toUpperCase();
                m.setType(name.contains("TP") || name.contains("ATELIER") ? "TP" : "COURS");
                matiereRepository.save(m);
            }
        }

        // Absences d'exemple pour le premier étudiant (si des étudiants existent déjà)
        if (absenceRepository.count() == 0) {
            List<Etudiant> etudiants = etudiantRepository.findAll();
            Matiere afcp = matiereRepository.findById("AFCP").orElse(null);
            Matiere soa = matiereRepository.findById("SOA").orElse(null);
            if (!etudiants.isEmpty() && afcp != null && soa != null) {
                Etudiant e = etudiants.get(0);
                absenceRepository.save(new Absence(null, afcp, e, LocalDate.of(2025, 11, 11), 1.5));
                absenceRepository.save(new Absence(null, afcp, e, LocalDate.of(2025, 10, 4), 3.0));
                absenceRepository.save(new Absence(null, soa, e, LocalDate.of(2025, 10, 20), 1.5));
                absenceRepository.save(new Absence(null, soa, e, LocalDate.of(2025, 10, 23), 1.5));
                absenceRepository.save(new Absence(null, soa, e, LocalDate.of(2025, 10, 16), 1.5));
            }
        }
    }

    private void saveOrUpdateMatiere(String codMat, String intMat, String description, String type) {
        Matiere m = matiereRepository.findById(codMat).orElse(new Matiere());
        m.setCodMat(codMat);
        m.setIntMat(intMat);
        m.setDescription(description);
        m.setType(type);
        matiereRepository.save(m);
    }
}
