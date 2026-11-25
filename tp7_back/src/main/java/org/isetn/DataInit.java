package org.isetn;

import java.time.LocalDate;
import java.util.List;
import org.isetn.entities.Absence;
import org.isetn.entities.ClassMat;
import org.isetn.entities.Classe;
import org.isetn.entities.Departement;
import org.isetn.entities.Etudiant;
import org.isetn.entities.Formation;
import org.isetn.entities.Matiere;
import org.isetn.entities.Note;
import org.isetn.entities.User;
import org.isetn.repository.AbsenceRepository;
import org.isetn.repository.ClassMatRepository;
import org.isetn.repository.ClasseRepository;
import org.isetn.repository.DepartementRepository;
import org.isetn.repository.EtudiantRepository;
import org.isetn.repository.FormationRepository;
import org.isetn.repository.MatiereRepository;
import org.isetn.repository.NoteRepository;
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
    private final ClassMatRepository classMatRepository;
    private final NoteRepository noteRepository;

    public DataInit(ClasseRepository c, FormationRepository f, UserRepository u,
                    DepartementRepository d, MatiereRepository m,
                    EtudiantRepository e, AbsenceRepository a,
                    ClassMatRepository cm, NoteRepository n) {
        this.classeRepository = c;
        this.formationRepository = f;
        this.userRepository = u;
        this.departementRepository = d;
        this.matiereRepository = m;
        this.etudiantRepository = e;
        this.absenceRepository = a;
        this.classMatRepository = cm;
        this.noteRepository = n;
    }

    @Override
    public void run(String... args) {
        if (departementRepository.count() == 0) {
            departementRepository.save(new Departement(null, "TI"));
            departementRepository.save(new Departement(null, "GE"));
        }
        Departement ti = departementRepository.findAll().stream()
                .filter(d -> "TI".equalsIgnoreCase(d.getNomDept()))
                .findFirst()
                .orElseGet(() -> departementRepository.save(new Departement(null, "TI")));

        Classe dsi33 = classeRepository.findAll().stream()
                .filter(c -> "DSI33".equalsIgnoreCase(c.getNomClass()))
                .findFirst()
                .orElse(null);
        if (dsi33 == null) {
            dsi33 = classeRepository.save(new Classe(null, "DSI33", 25, ti));
        }

        if (classeRepository.findAll().stream().noneMatch(c -> "DSI21".equalsIgnoreCase(c.getNomClass()))) {
            classeRepository.save(new Classe(null, "DSI21", 20, ti));
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
        Formation formDev = formationRepository.findAll().get(0);

        if (userRepository.findByEmailAndPassword("admin@gmail.com", "admin") == null) {
            userRepository.save(new User(null, "admin@gmail.com", "admin"));
        }

        saveOrUpdateMatiere("AFCP", "AFCP (TP)", "Atelier framework cross-platform", "TP");
        saveOrUpdateMatiere("SOA", "SOA (Cours)", "Architecture orientee services", "COURS");
        saveOrUpdateMatiere("WEB_C", "WEB (Cours)", "Developpement web cours", "COURS");
        saveOrUpdateMatiere("WEB_TP", "WEB (TP)", "Developpement web TP", "TP");

        Matiere afcp = matiereRepository.findById("AFCP").orElse(null);
        Matiere soa = matiereRepository.findById("SOA").orElse(null);
        Matiere webC = matiereRepository.findById("WEB_C").orElse(null);
        Matiere webTp = matiereRepository.findById("WEB_TP").orElse(null);

        if (classMatRepository.findByClasseCodClass(dsi33.getCodClass()).isEmpty()) {
            if (afcp != null) classMatRepository.save(new ClassMat(null, afcp, dsi33, 3.0, 45.0));
            if (soa != null) classMatRepository.save(new ClassMat(null, soa, dsi33, 2.0, 30.0));
            if (webC != null) classMatRepository.save(new ClassMat(null, webC, dsi33, 2.0, 30.0));
            if (webTp != null) classMatRepository.save(new ClassMat(null, webTp, dsi33, 1.5, 22.5));
        }


        List<Etudiant> dsi33Students = etudiantRepository.findByClasseCodClass(dsi33.getCodClass());
        if (dsi33Students.isEmpty()) {
            Etudiant e1 = etudiantRepository.save(new Etudiant(null, "Ben Foulen1", "Foulen1", LocalDate.of(2003, 5, 12), "Nabeul", dsi33, formDev));
            Etudiant e2 = etudiantRepository.save(new Etudiant(null, "Ben Foulen2", "Foulen2", LocalDate.of(2003, 8, 25), "Tunis", dsi33, formDev));
            Etudiant e3 = etudiantRepository.save(new Etudiant(null, "Ben Foulen3", "Foulen3", LocalDate.of(2002, 11, 30), "Sousse", dsi33, formDev));
            dsi33Students = List.of(e1, e2, e3);
        }

        if (noteRepository.count() == 0) {
            for (Etudiant e : dsi33Students) {
                if (e.getNom().contains("1")) {
                    if (afcp != null) noteRepository.save(new Note(null, e, afcp, 16.0, 15.0, 14.0, 15.5));
                    if (soa != null) noteRepository.save(new Note(null, e, soa, null, null, 13.0, 14.0));
                    if (webC != null) noteRepository.save(new Note(null, e, webC, null, null, 12.0, 13.5));
                    if (webTp != null) noteRepository.save(new Note(null, e, webTp, 17.0, 16.0, 15.0, 16.0));
                } else if (e.getNom().contains("2")) {
                    if (afcp != null) noteRepository.save(new Note(null, e, afcp, 12.0, 13.0, 11.0, 12.5));
                    if (soa != null) noteRepository.save(new Note(null, e, soa, null, null, 10.0, 11.5));
                    if (webC != null) noteRepository.save(new Note(null, e, webC, null, null, 11.5, 12.0));
                    if (webTp != null) noteRepository.save(new Note(null, e, webTp, 13.0, 14.0, 12.5, 13.0));
                } else {
                    if (afcp != null) noteRepository.save(new Note(null, e, afcp, 18.0, 17.5, 16.0, 17.0));
                    if (soa != null) noteRepository.save(new Note(null, e, soa, null, null, 15.0, 16.5));
                    if (webC != null) noteRepository.save(new Note(null, e, webC, null, null, 14.0, 15.0));
                    if (webTp != null) noteRepository.save(new Note(null, e, webTp, 19.0, 18.0, 17.0, 18.5));
                }
            }
        }
        if (absenceRepository.count() == 0 && !dsi33Students.isEmpty()) {
            Etudiant e1 = dsi33Students.get(0);
            Etudiant e2 = dsi33Students.size() > 1 ? dsi33Students.get(1) : e1;

            if (afcp != null) {
                absenceRepository.save(new Absence(null, afcp, e1, LocalDate.of(2025, 10, 5), 3.0));
                absenceRepository.save(new Absence(null, afcp, e1, LocalDate.of(2025, 10, 12), 3.0));
                absenceRepository.save(new Absence(null, afcp, e2, LocalDate.of(2025, 10, 19), 3.0));
                absenceRepository.save(new Absence(null, afcp, e2, LocalDate.of(2025, 10, 26), 3.0));
            }
            if (soa != null) {
                absenceRepository.save(new Absence(null, soa, e1, LocalDate.of(2025, 10, 8), 1.5));
                absenceRepository.save(new Absence(null, soa, e1, LocalDate.of(2025, 10, 15), 1.5));
                absenceRepository.save(new Absence(null, soa, e2, LocalDate.of(2025, 10, 22), 1.5));
            }
            if (webTp != null) {
                absenceRepository.save(new Absence(null, webTp, e1, LocalDate.of(2025, 11, 2), 3.0));
                absenceRepository.save(new Absence(null, webTp, e2, LocalDate.of(2025, 11, 9), 3.0));
            }
            if (webC != null) {
                absenceRepository.save(new Absence(null, webC, e1, LocalDate.of(2025, 11, 4), 1.5));
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