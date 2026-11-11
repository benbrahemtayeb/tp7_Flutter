package org.isetn.RestControllers;

import java.util.List;
import org.isetn.entities.Etudiant;
import org.isetn.repository.EtudiantRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/etudiants")
public class EtudiantController {

    @Autowired
    private EtudiantRepository etudiantRepository;

    @GetMapping
    public List<Etudiant> getAll() {
        return etudiantRepository.findAll();
    }

    @GetMapping("/classe/{codClass}")
    public List<Etudiant> getByClasse(@PathVariable Integer codClass) {
        return etudiantRepository.findByClasseCodClass(codClass);
    }

    @PostMapping
    public Etudiant add(@RequestBody Etudiant e) {
        return etudiantRepository.save(e);
    }

    @PutMapping("/{id}")
    public Etudiant update(@PathVariable Integer id, @RequestBody Etudiant e) {
        e.setId(id);
        return etudiantRepository.save(e);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Integer id) {
        etudiantRepository.deleteById(id);
    }
}
