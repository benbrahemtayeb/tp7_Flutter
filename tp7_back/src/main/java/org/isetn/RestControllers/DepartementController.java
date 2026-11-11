package org.isetn.RestControllers;

import java.util.List;
import org.isetn.entities.Departement;
import org.isetn.repository.DepartementRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/departements")
public class DepartementController {

    @Autowired
    private DepartementRepository departementRepository;

    @GetMapping
    public List<Departement> getAll() {
        return departementRepository.findAll();
    }

    @PostMapping
    public Departement add(@RequestBody Departement d) {
        return departementRepository.save(d);
    }
}
